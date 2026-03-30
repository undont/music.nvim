describe("config", function()
    local config

    before_each(function()
        -- Force re-require to reset state between tests
        package.loaded["music.config"] = nil
        config = require("music.config")
    end)

    describe("defaults", function()
        it("has poll_interval", function()
            assert.equal(1000, config.options.poll_interval)
        end)

        it("has preferred_backend set to apple_music", function()
            assert.equal("apple_music", config.options.preferred_backend)
        end)

        it("has position set to bottom-left", function()
            assert.equal("bottom-left", config.options.position)
        end)

        it("has window settings", function()
            assert.equal(30, config.options.window.width)
            assert.equal(16, config.options.window.expanded_height)
            assert.equal(3, config.options.window.compact_height)
            assert.equal(1500, config.options.window.expand_duration)
        end)

        it("has highlight settings", function()
            assert.equal("Normal", config.options.highlights.background)
            assert.equal("FloatBorder", config.options.highlights.border)
            assert.equal("NormalFloat", config.options.highlights.text)
        end)
    end)

    describe("apply", function()
        it("overrides top-level options", function()
            config.apply({ poll_interval = 5000 })
            assert.equal(5000, config.options.poll_interval)
        end)

        it("preserves unspecified options", function()
            config.apply({ poll_interval = 5000 })
            assert.equal("apple_music", config.options.preferred_backend)
            assert.equal("bottom-left", config.options.position)
        end)

        it("deep-merges nested window options", function()
            config.apply({ window = { width = 40 } })
            assert.equal(40, config.options.window.width)
            -- Other window options should be preserved
            assert.equal(16, config.options.window.expanded_height)
            assert.equal(3, config.options.window.compact_height)
        end)

        it("deep-merges nested highlight options", function()
            config.apply({ highlights = { background = "MyCustomHl" } })
            assert.equal("MyCustomHl", config.options.highlights.background)
            assert.equal("FloatBorder", config.options.highlights.border)
        end)

        it("handles nil opts gracefully", function()
            config.apply(nil)
            -- Defaults should remain
            assert.equal(1000, config.options.poll_interval)
        end)

        it("handles empty opts table", function()
            config.apply({})
            assert.equal(1000, config.options.poll_interval)
        end)

        it("sets preferred_backend to apple_music", function()
            config.apply({ preferred_backend = "apple_music" })
            assert.equal("apple_music", config.options.preferred_backend)
        end)

        it("sets preferred_backend to spotify", function()
            config.apply({ preferred_backend = "spotify" })
            assert.equal("spotify", config.options.preferred_backend)
        end)

        it("accepts unknown preferred_backend values without error", function()
            -- Invalid values fall through to auto-detect in backend.lua
            config.apply({ preferred_backend = "invalid_value" })
            assert.equal("invalid_value", config.options.preferred_backend)
        end)
    end)
end)
