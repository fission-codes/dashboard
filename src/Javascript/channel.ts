import * as uint8arrays from 'uint8arrays'


/** A channel interface with send/receive intended for small message payloads, because it's non-streaming */
export interface Channel<T> {
    send(message: T): Promise<void>
    receive(options?: ReceiveOptions): Promise<T>
}

export interface ReceiveOptions {
    signal?: AbortSignal
}


/** Mainly used for testing */
export class QueuedChannel<T> implements Channel<T> {
    private messages: T[] = []

    async send(message: T): Promise<void> {
        this.messages.push(message)
    }

    async receive(): Promise<T> {
        const msg = this.messages[0]
        this.messages = this.messages.slice(1, this.messages.length)
        return msg
    }
}


export class WebSocketChannel implements Channel<ArrayBuffer> {
    private readonly socket: WebSocket
    private readonly queue: Promise<ArrayBuffer>[]

    constructor(socket: WebSocket) {
        this.socket = socket
        this.queue = []

        this.socket.addEventListener("message", (msg: MessageEvent<Blob>) => {
            this.queue.push(msg.data.arrayBuffer())
        })
        this.socket.addEventListener("error", e => {
            this.queue.push(new Promise((_resolve, reject) => reject(e)))
        })
    }

    async send(message: ArrayBuffer): Promise<void> {
        this.socket.send(message)
    }

    async receive(options?: ReceiveOptions): Promise<ArrayBuffer> {
        // If the socket got closed, throw an error
        if (this.socket.readyState === WebSocket.CLOSING || this.socket.readyState === WebSocket.CLOSED) {
            throw new Error("Can't receive messages. WebSocket already closed.")
        }
        // If the queue is empty, wait for the next message, an error, the socket closing or the signal aborting
        if (this.queue.length === 0) {
            await new Promise((resolve, reject) => {
                this.socket.addEventListener("message", () => resolve(null), { once: true })
                this.socket.addEventListener("error", e => reject(e), { once: true })
                this.socket.addEventListener("close", () => reject(new Error("Can't receive messages. WebSocket already closed.")), { once: true })
                if (options?.signal != null) {
                    options.signal.addEventListener("abort", () => reject(new Error("WebSocket message receiving aborted.")), { once: true })
                }
            })
        }
        return await this.queue.splice(0, 1)[0]
    }
}


export class EncryptedChannel implements Channel<ArrayBuffer> {
    private readonly sessionKey: CryptoKey
    private readonly baseChannel: Channel<ArrayBuffer>
    private readonly crypto: SubtleCrypto

    constructor(sessionKey: CryptoKey, baseChannel: Channel<ArrayBuffer>, crypto?: SubtleCrypto) {
        this.sessionKey = sessionKey
        this.baseChannel = baseChannel
        // Try the argument, or nodejs webcrypto, or browser context crypto
        this.crypto = crypto || (globalThis.crypto as any).webcrypto?.subtle || globalThis.crypto.subtle
    }

    async send(message: ArrayBuffer): Promise<void> {
        const iv = globalThis.crypto.getRandomValues(new Uint8Array(16))
        const msg = await this.crypto.encrypt(
            {
                name: "AES-GCM",
                iv: iv
            },
            this.sessionKey,
            message
        )
        await this.baseChannel.send(new TextEncoder().encode(JSON.stringify({
            iv: uint8arrays.toString(iv, "base64pad"),
            msg: uint8arrays.toString(new Uint8Array(msg), "base64pad"),
        })).buffer)
    }

    async receive(options: ReceiveOptions): Promise<ArrayBuffer> {
        const raw = await this.baseChannel.receive(options)
        const { iv, msg } = JSON.parse(new TextDecoder().decode(raw))
        return await this.crypto.decrypt(
            {
                name: "AES-GCM",
                iv: uint8arrays.fromString(iv, "base64pad").buffer,
            },
            this.sessionKey,
            uint8arrays.fromString(msg, "base64pad").buffer
        )
    }
}

export class TextEncodedChannel implements Channel<string> {
    private readonly baseChannel: Channel<ArrayBuffer>

    constructor(baseChannel: Channel<ArrayBuffer>) {
        this.baseChannel = baseChannel
    }

    async send(message: string): Promise<void> {
        await this.baseChannel.send(new TextEncoder().encode(message).buffer)
    }

    async receive(options?: ReceiveOptions): Promise<string> {
        return new TextDecoder().decode(new Uint8Array(await this.baseChannel.receive(options)))
    }
}

export class JSONChannel implements Channel<any> {
    private readonly baseChannel: Channel<string>

    constructor(baseChannel: Channel<string>) {
        this.baseChannel = baseChannel
    }

    async send(message: any): Promise<void> {
        await this.baseChannel.send(JSON.stringify(message))
    }

    async receive(options?: ReceiveOptions): Promise<any> {
        return JSON.parse(await this.baseChannel.receive(options))
    }
}
