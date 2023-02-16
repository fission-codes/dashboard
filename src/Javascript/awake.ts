// This module implements the AWAKE protocol (https://whitepaper.fission.codes/accounts/login/quake)
// AWAKE stands for "Authorization With Authenticated Key Exchange"
// It's used for linking fission accounts across devices

import * as uint8arrays from 'uint8arrays'
import { Crypto } from 'webnative'
import * as did from 'webnative/did/index'
import * as ucan from 'webnative/ucan/index'
import { Channel, EncryptedChannel, JSONChannel, TextEncodedChannel } from './channel'


export const RSA_KEY_ALGO = {
    name: "RSA-OAEP",
    modulusLength: 2048,
    publicExponent: new Uint8Array([ 0x01, 0x00, 0x01 ]),
    hash: { name: "SHA-256" }
}


/**
 * Establishes a secure connection with a given DID.
 *
 * This assumes both connection partners know of this sender's
 * root user DID, which authenticates the secure channel, preventing
 * person-in-the-middle attacks.
 */
export async function establishSecureChannelWith(
    { crypto }: { crypto: Crypto.Implementation },
    recipientDID: string,
    baseChannel: Channel<ArrayBuffer>,
    authentication?: string, // an encoded UCAN. Not needed if this is in the context of the root DID
): Promise<EncryptedChannel> {
    const subtleCrypto = getCrypto()
    const { publicKey } = did.didToPublicKey(crypto, recipientDID) // Also ensures that it's a valid DID
    const recipientPubKey = await subtleCrypto.importKey(
        "spki",
        publicKey,
        RSA_KEY_ALGO,
        false,
        [ "encrypt" ]
    )

    const sessionKey = await subtleCrypto.generateKey(
        {
            name: "AES-GCM",
            length: 256
        },
        true,
        [ "encrypt", "decrypt" ]
    )

    const sessionKeyRaw = await subtleCrypto.exportKey("raw", sessionKey)
    const sessionKeyBase64 = uint8arrays.toString(new Uint8Array(sessionKeyRaw), "base64pad")

    const encryptedSessionKey = await subtleCrypto.encrypt(
        { name: "RSA-OAEP" },
        recipientPubKey,
        sessionKeyRaw
    )

    const sessionKeyExchangeUcan = ucan.encode(await ucan.build({
        dependencies: { crypto },

        issuer: await did.write(crypto),
        audience: recipientDID,
        lifetimeInSeconds: 60 * 5, // 5 minutes
        facts: [ { sessionKey: sessionKeyBase64 } ],
        potency: null,
        proof: authentication,
    }))


    const iv = window.crypto.getRandomValues(new Uint8Array(16))
    const msg = await window.crypto.subtle.encrypt(
        {
            name: "AES-GCM",
            iv: iv
        },
        sessionKey,
        uint8arrays.fromString(sessionKeyExchangeUcan)
    )

    baseChannel.send(new TextEncoder().encode(JSON.stringify({
        iv: uint8arrays.toString(new Uint8Array(iv), "base64pad"),
        msg: uint8arrays.toString(new Uint8Array(msg), "base64pad"),
        sessionKey: uint8arrays.toString(new Uint8Array(encryptedSessionKey), "base64pad"),
    })).buffer)

    return new EncryptedChannel(sessionKey, baseChannel, subtleCrypto)
}


export interface AuthorizeParams {
    inquirerThrowawayDID: string
    channel: Channel<ArrayBuffer>
    validChallenge(challenge: Challenge): Promise<boolean>
    readKey: string
}

export interface AuthorizeOptions {
    signal?: AbortSignal
    retriesOnMessages?: number
    retryIntervalMs?: number
    log(msg: string, ...data: any[]): void
}

export interface Challenge {
    did: string,
    pin: number[],
}

export async function authorize(
    { crypto }: { crypto: Crypto.Implementation },
    { inquirerThrowawayDID, channel, validChallenge, readKey }: AuthorizeParams,
    possibleOptions?: AuthorizeOptions
): Promise<boolean> {
    const options: AuthorizeOptions = {
        ...possibleOptions,
        retriesOnMessages: possibleOptions?.retriesOnMessages || 10,
        retryIntervalMs: possibleOptions?.retryIntervalMs || 100,
        log: possibleOptions?.log || function log() { },
    }
    const retryOptions = {
        interval: options.retryIntervalMs,
        maxRetries: options.retriesOnMessages,
        signal: options.signal,
    }

    // asserts that the DID is valid
    did.didToPublicKey(crypto, inquirerThrowawayDID)

    const { challengeData, encryptedChannel } = await retry(async () => {

        options.log("Trying to establish a secure channel with", inquirerThrowawayDID)

        const encryptedChannel = new JSONChannel(new TextEncodedChannel(
            await establishSecureChannelWith({ crypto }, inquirerThrowawayDID, channel)
        ))

        options.log("Retrieving challenge and real DID")

        const challengeData: Challenge = await encryptedChannel.receive()

        if (!Array.isArray(challengeData.pin) || !challengeData.pin.every(n => typeof n === "number")) {
            throw new Error(`Received invalid challenge response. Pin is not an array of numbers: ${JSON.stringify(challengeData.pin)}`)
        }

        // asserts that the DID is valid
        did.didToPublicKey(crypto, challengeData.did)

        return {
            challengeData,
            encryptedChannel,
        }

    }, retryOptions)

    options.log("Got challenge: ", challengeData)

    options.log("Asking for validation")

    const valid = await validChallenge(challengeData)

    if (!valid) {
        return false
    }

    const linkingUCAN = ucan.encode(await ucan.build({
        dependencies: { crypto },

        issuer: await did.agent(crypto),
        audience: challengeData.did,
        lifetimeInSeconds: 60 * 60 * 24 * 30 * 12 * 1000, // 1000 years
        potency: "SUPER_USER",
    }))

    options.log("Sending Ucan", linkingUCAN)

    await encryptedChannel.send({
        readKey: readKey,
        ucan: linkingUCAN,
    })

    options.log("Authorization done")

    return true
}



///////////////
// Utilities
///////////////

function getCrypto(): SubtleCrypto {
    const crypto =
        // nodejs v15+
        (globalThis.crypto as any).webcrypto?.subtle
        // browser
        || globalThis.crypto.subtle

    if (crypto == null) {
        throw new Error("Couldn't find access to the WebCrypto API on this platform.")
    }

    return crypto
}

export async function retry<T>(
    action: () => Promise<T>,
    { maxRetries, signal, interval }: { maxRetries?: number, signal?: AbortSignal | null, interval?: number } = { maxRetries: -1, signal: null, interval: 200 }
): Promise<T> {
    const errors: Error[] = []
    maxRetries = maxRetries || -1
    interval = interval || 200
    while (maxRetries-- !== 0) {
        if (signal != null && signal.aborted) {
            errors.push(new Error("Action aborted."))
            throw errors
        }
        try {
            return await action()
        } catch (e) {
            errors.push(e)
        }
        await new Promise(resolve => setTimeout(resolve, interval))
    }
    throw errors
}
