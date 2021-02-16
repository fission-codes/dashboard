# Variables
# =========

dist := "build"
node_bin := "./node_modules/.bin"
workbox_config := "./src/Javascript/workbox.config.cjs"



# Tasks
# =====

@default: dev-build
	just dev-server & just watch


@hot:
	just dev-build
	just hot-server & \
	just watch-css & \
	just watch-html & \
	just watch-javascript



# Parts
# =====

@css-large:
	echo "💄  Compiling CSS"
	mkdir -p src/Library/Css
	pnpx etc src/Css/Application.css \
		--config src/Css/Tailwind.js \
		--elm-module Css.Classes \
		--elm-path src/Library/Css/Classes.elm \
		--output {{dist}}/application.css \
		--post-plugin-before postcss-import

@css-small:
	echo "💄  Compiling Minified CSS"
	mkdir -p src/Library/Css
	NODE_ENV=production pnpx etc src/Css/Application.css \
		--config src/Css/Tailwind.js \
		--elm-module Css.Classes \
		--elm-path src/Library/Css/Classes.elm \
		--output {{dist}}/application.css \
		--post-plugin-before postcss-import \
		--purge-content {{dist}}/index.html \
		--purge-content {{dist}}/bundle.min.js \
		--purge-content {{dist}}/application.js \


@elm-dev:
	echo "🌳  Compiling Elm"
	elm make \
		--output {{dist}}/application.js \
		src/Application/Main.elm


@elm-production:
	echo "🌳  Compiling Elm (optimised)"
	elm make \
		--output {{dist}}/application.js \
		--optimize \
		src/Application/Main.elm


@favicons:
	echo "📎  Copying favicons"
	cp -RT src/Favicons/ {{dist}}


@fonts:
	echo "🔤  Copying fonts"
	mkdir -p {{dist}}/fonts/
	cp node_modules/fission-kit/fonts/**/*.woff2 {{dist}}/fonts/


@html:
	echo "📜  Compiling HTML"
	mustache \
		config/default.yml src/Html/Main.html \
		> {{dist}}/index.html


@images:
	echo "🌄  Copying images"
	cp -RT node_modules/fission-kit/images/ {{dist}}/images/
	cp -RT src/Images/ {{dist}}/images/


@javascript:
	echo "⚙️  Bundling javascript"
	{{node_bin}}/esbuild \
		--bundle \
		--minify \
		--sourcemap \
		--outfile={{dist}}/bundle.min.js \
		src/Javascript/index.js


@manifests:
	echo "🅰️  Copying manifest files"
	cp -RT src/Manifests/ {{dist}}



# Development
# ===========


@clean:
	rm -rf {{dist}} || true
	mkdir -p {{dist}}


@dev-build: clean html css-large javascript elm-dev fonts favicons manifests images


@production-build: clean html elm-production javascript css-small fonts favicons manifests images production-service-worker


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


@install-deps:
	pnpm install


@watch:
	echo "👀  Watching for changes"
	just watch-css & \
	just watch-elm & \
	just watch-html & \
	just watch-javascript


@watch-css:
	watchexec -p -w src -f "*/Css/**/*.*" -i build -- just css-large


@watch-elm:
	watchexec -p -w src -e elm -- just elm-dev


@watch-html:
	watchexec -p -w src -e html -- just html


@watch-javascript:
	watchexec -p -w src -e js -- just javascript
