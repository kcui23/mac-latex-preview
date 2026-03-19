APP_NAME = LatexPreview
BUILD_DIR = build
APP_BUNDLE = $(BUILD_DIR)/$(APP_NAME).app
SOURCES = $(wildcard Sources/*.swift)
KATEX_VER = 0.16.11

.PHONY: all clean run

all: $(APP_BUNDLE)

Resources/katex.min.js:
	@echo "Downloading KaTeX v$(KATEX_VER)..."
	@curl -sL "https://github.com/KaTeX/KaTeX/releases/download/v$(KATEX_VER)/katex.tar.gz" -o /tmp/katex.tar.gz
	@tar xzf /tmp/katex.tar.gz -C /tmp
	@cp /tmp/katex/katex.min.js /tmp/katex/katex.min.css Resources/
	@cp -r /tmp/katex/fonts Resources/
	@rm -rf /tmp/katex /tmp/katex.tar.gz
	@echo "KaTeX ready."

$(APP_BUNDLE): $(SOURCES) Info.plist Resources/render.html Resources/katex.min.js
	@mkdir -p $(APP_BUNDLE)/Contents/MacOS $(APP_BUNDLE)/Contents/Resources
	swiftc -O -o $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME) $(SOURCES) \
		-framework Cocoa -framework WebKit -suppress-warnings
	@cp Info.plist $(APP_BUNDLE)/Contents/
	@cp Resources/render.html Resources/katex.min.js Resources/katex.min.css $(APP_BUNDLE)/Contents/Resources/
	@cp -r Resources/fonts $(APP_BUNDLE)/Contents/Resources/

run: all
	@open $(APP_BUNDLE)

clean:
	rm -rf $(BUILD_DIR)
