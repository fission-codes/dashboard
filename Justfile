dist := "build"
node_bin := "./node_modules/.bin"


@default: dev-build
	just dev-server & just watch



# Parts
# =====

@css-large:
	echo "💄  Compiling CSS"
	mkdir -p src/Library/Css
	pnpx etc src/Css/Application.css \
		--config src/Css/Tailwind.js \
		--elm-module Css.Classes \
		--elm-path src/Library/Css/Classes.elm \
		--output {{dist}}/application.css


@elm-dev:
	echo "🌳  Compiling Elm"
	elm make \
		--output {{dist}}/application.js \
		src/Application/Main.elm


@hot:
	just hot-server & \
	just watch-css & \
	just watch-html


@hot-server:
	echo "🔥  Start a hot-reloading elm-live server at http://localhost:8004"
	{{node_bin}}/elm-live src/Application/Main.elm \
		--hot \
		--port=8004 \
		--pushstate \
		--dir=build \
		-- \
		--output={{dist}}/application.js \
		--debug


@fonts:
	echo "🔤  Copying fonts"
	mkdir -p {{dist}}/fonts/
	cp node_modules/fission-kit/fonts/**/*.woff2 {{dist}}/fonts/


@images:
	echo "🌄  Copying images"
	cp -RT node_modules/fission-kit/images/ {{dist}}/images/
	cp -RT src/Images/ {{dist}}/images/


@html:
	echo "📜  Compiling HTML"
	mustache \
		--layout src/Html/Layout.html \
		config/default.yml src/Html/Application.html \
		> {{dist}}/index.html



# Development
# ===========


@clean:
	rm -rf {{dist}} || true
	mkdir -p {{dist}}


@dev-build: clean html css-large elm-dev fonts images


@dev-server:
	echo "🧞  Putting up a server for ya"
	echo "http://localhost:8004"
	devd --quiet build --port=8004 --all


@install-deps:
	pnpm install


@watch:
	echo "👀  Watching for changes"
	just watch-css & \
	just watch-elm & \
	just watch-html


@watch-css:
	watchexec -p -w src -f "*/Css/**/*.*" -i build -- just css-large


@watch-elm:
	watchexec -p -w src -e elm -- just elm-dev


@watch-html:
	watchexec -p -w src -e html -- just html
