# Variables
# =========

config := "production"
dist := "build"
node_bin := "./node_modules/.bin"
workbox_config := "./src/Javascript/workbox.config.cjs"



# Tasks
# =====

@default: dev-build
	just config={{config}} dev-server & just config={{config}} watch


@hot:
	just config={{config}} dev-build
	just config={{config}} hot-server & \
	just config={{config}} watch-css & \
	just config={{config}} watch-html & \
	just config={{config}} watch-typescript-dev


@hot-recovery:
	just config={{config}} dev-build
	just config={{config}} hot-server-recovery & \
	just config={{config}} watch-css & \
	just config={{config}} watch-html & \
	just config={{config}} watch-typescript-dev


# Parts
# =====

@css:
	echo "💄  Compiling CSS"
	pnpx node src/Javascript/generate-css-modules.js


@elm-dev:
	echo "🌳  Compiling Elm"
	elm make \
		--output {{dist}}/application.js \
		src/Application/Main.elm
	elm make \
		--output {{dist}}/recover/application.js \
		src/Application/Recovery/Main.elm


@elm-production:
	echo "🌳  Compiling Elm (optimised)"
	elm make \
		src/Application/Main.elm \
		--output {{dist}}/application.js \
		--optimize
	elm make \
		--output {{dist}}/recover/application.js \
		--optimize \
		src/Application/Recovery/Main.elm


@favicons:
	echo "📎  Copying favicons"
	cp -RT src/Favicons/ {{dist}}


@fonts:
	echo "🔤  Copying fonts"
	mkdir -p {{dist}}/fonts/
	cp node_modules/fission-kit/fonts/**/*.woff2 {{dist}}/fonts/


@html:
	echo "📜  Copying HTML"
	cp src/Html/Main.html {{dist}}/index.html
	mkdir -p {{dist}}/recover
	cp src/Html/Recovery/Main.html {{dist}}/recover/index.html


@images:
	echo "🌄  Copying images"
	cp -RT node_modules/fission-kit/images/ {{dist}}/images/
	cp -RT src/Images/ {{dist}}/images/


@typescript-dev:
	echo "⚙️  Bundling typescript"
	{{node_bin}}/esbuild \
		--define:CONFIG_ENVIRONMENT="\"{{config}}\"" \
		--define:CONFIG_API_ENDPOINT="$(jq .API_ENDPOINT config/{{config}}.json)" \
		--define:CONFIG_LOBBY="$(jq .LOBBY config/{{config}}.json)" \
		--define:CONFIG_USER="$(jq .USER config/{{config}}.json)" \
		--bundle \
		--sourcemap \
		--outfile={{dist}}/bundle.min.js \
		src/Javascript/index.ts
	{{node_bin}}/esbuild \
		--define:CONFIG_ENVIRONMENT="\"{{config}}\"" \
		--define:CONFIG_API_ENDPOINT="$(jq .API_ENDPOINT config/{{config}}.json)" \
		--define:CONFIG_LOBBY="$(jq .LOBBY config/{{config}}.json)" \
		--define:CONFIG_USER="$(jq .USER config/{{config}}.json)" \
		--bundle \
		--sourcemap \
		--outfile={{dist}}/recover/bundle.min.js \
		src/Javascript/recovery.ts


@typescript-prod:
	echo "⚙️  Bundling minified typescript"
	{{node_bin}}/esbuild \
		--define:CONFIG_ENVIRONMENT="\"{{config}}\"" \
		--define:CONFIG_API_ENDPOINT="$(jq .API_ENDPOINT config/{{config}}.json)" \
		--define:CONFIG_LOBBY="$(jq .LOBBY config/{{config}}.json)" \
		--define:CONFIG_USER="$(jq .USER config/{{config}}.json)" \
		--bundle \
		--minify \
		--sourcemap \
		--outfile={{dist}}/bundle.min.js \
		src/Javascript/index.ts
	{{node_bin}}/esbuild \
		--define:CONFIG_ENVIRONMENT="\"{{config}}\"" \
		--define:CONFIG_API_ENDPOINT="$(jq .API_ENDPOINT config/{{config}}.json)" \
		--define:CONFIG_LOBBY="$(jq .LOBBY config/{{config}}.json)" \
		--define:CONFIG_USER="$(jq .USER config/{{config}}.json)" \
		--bundle \
		--minify \
		--sourcemap \
		--outfile={{dist}}/recover/bundle.min.js \
		src/Javascript/recovery.ts


@manifests:
	echo "🅰️  Copying manifest files"
	cp -RT src/Manifests/ {{dist}}



# Development
# ===========


@clean:
	rm -rf {{dist}} || true
	mkdir -p {{dist}}


@dev-build: clean html css typescript-dev elm-dev fonts favicons manifests images


@build: clean html css elm-production typescript-prod fonts favicons manifests images production-service-worker


@production-build:
	just config=production build


@production-service-worker:
	echo "⚙️  Generating service worker"
	NODE_ENV=production pnpx workbox generateSW {{workbox_config}}


@dev-server:
	echo "🧞  Putting up a server for ya"
	echo "http://localhost:8004"
	devd --quiet build --port=8004 --all


@hot-server:
	echo "🔥  Start a hot-reloading elm-live server at http://localhost:8004"
	{{node_bin}}/elm-live src/Application/Main.elm \
		--hot \
		--host 0.0.0.0 \
		--port=8004 \
		--pushstate \
		--dir={{dist}} \
		-- \
		--output={{dist}}/application.js \
		--debug


@hot-server-recovery:
	echo "🔥  Start a hot-reloading (only for the recovery app!) elm-live server at http://localhost:8004"
	{{node_bin}}/elm-live src/Application/Recovery/Main.elm \
		--hot \
		--host 0.0.0.0 \
		--port=8004 \
		--dir={{dist}} \
		-- \
		--output={{dist}}/recover/application.js \
		--debug


@install-deps:
	pnpm install


@watch:
	echo "👀  Watching for changes"
	just config={{config}} watch-css & \
	just config={{config}} watch-elm & \
	just config={{config}} watch-html & \
	just config={{config}} watch-typescript-dev


@watch-css:
	watchexec -p -w src -f "*/Css/**/*.*" -i build -- just config={{config}} css


@watch-elm:
	watchexec -p -w src -e elm -- just config={{config}} elm-dev


@watch-html:
	watchexec -p -w src -e html -- just config={{config}} html


@watch-typescript-dev:
	watchexec -p -w src -e ts -- just config={{config}} typescript-dev
