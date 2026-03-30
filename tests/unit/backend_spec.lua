describe("backend", function()
    local config
    local mock_apple, mock_spotify

    -- Create fresh mock backends for each test
    local function make_mock_backend(name, track)
        return {
            _name = name,
            get_now_playing = function(cb)
                cb(track)
            end,
            play = function() end,
            pause = function() end,
            next_track = function() end,
            prev_track = function() end,
            toggle_play = function(cb)
                if cb then
                    cb()
                end
            end,
            invalidate_cache = function() end,
            extract_artwork = function(cb)
                cb(nil, "no artwork")
            end,
        }
    end

    before_each(function()
        -- Reset all relevant modules
        package.loaded["music.backend"] = nil
        package.loaded["music.config"] = nil

        config = require("music.config")

        mock_apple = make_mock_backend("apple_music", {
            name = "Apple Song",
            artist = "Apple Artist",
            album = "Apple Album",
            art_url = nil,
            progress_ms = 10000,
            duration_ms = 200000,
            is_playing = true,
        })

        mock_spotify = make_mock_backend("spotify", {
            name = "Spotify Song",
            artist = "Spotify Artist",
            album = "Spotify Album",
            art_url = "https://example.com/art.jpg",
            progress_ms = 30000,
            duration_ms = 180000,
            is_playing = true,
        })

        -- Inject mock backends into package.loaded
        package.loaded["music.apple_music"] = mock_apple
        package.loaded["music.spotify"] = mock_spotify
        package.loaded["music.spotify_local"] = mock_spotify
    end)

    describe("preferred_backend config", function()
        it("uses apple_music backend when preferred_backend is apple_music", function()
            config.apply({ preferred_backend = "apple_music" })
            local backend = require("music.backend")
            local result

            backend.get_now_playing(function(track)
                result = track
            end)

            assert.is_not_nil(result)
            assert.equal("Apple Song", result.name)
        end)

        it("uses spotify backend when preferred_backend is spotify", function()
            config.apply({ preferred_backend = "spotify" })
            local backend = require("music.backend")
            local result

            backend.get_now_playing(function(track)
                result = track
            end)

            assert.is_not_nil(result)
            assert.equal("Spotify Song", result.name)
        end)
    end)

    describe("play/pause/next/prev routing", function()
        it("routes play to active backend", function()
            config.apply({ preferred_backend = "apple_music" })
            local backend = require("music.backend")
            local called = false
            mock_apple.play = function()
                called = true
            end

            backend.play()
            assert.is_true(called)
        end)

        it("routes pause to active backend", function()
            config.apply({ preferred_backend = "spotify" })
            local backend = require("music.backend")
            local called = false
            mock_spotify.pause = function()
                called = true
            end

            backend.pause()
            assert.is_true(called)
        end)

        it("routes next_track to active backend", function()
            config.apply({ preferred_backend = "apple_music" })
            local backend = require("music.backend")
            local called = false
            mock_apple.next_track = function()
                called = true
            end

            backend.next_track()
            assert.is_true(called)
        end)

        it("routes prev_track to active backend", function()
            config.apply({ preferred_backend = "apple_music" })
            local backend = require("music.backend")
            local called = false
            mock_apple.prev_track = function()
                called = true
            end

            backend.prev_track()
            assert.is_true(called)
        end)

        it("routes toggle_play to active backend with callback", function()
            config.apply({ preferred_backend = "spotify" })
            local backend = require("music.backend")
            local cb_called = false
            mock_spotify.toggle_play = function(cb)
                if cb then
                    cb()
                end
            end

            backend.toggle_play(function()
                cb_called = true
            end)
            assert.is_true(cb_called)
        end)
    end)

    describe("invalidate_cache", function()
        it("forces re-detection on next call", function()
            config.apply({ preferred_backend = "apple_music" })
            local backend = require("music.backend")
            local result

            -- First call uses apple_music
            backend.get_now_playing(function(track)
                result = track
            end)
            assert.equal("Apple Song", result.name)

            -- Change preference and invalidate
            config.apply({ preferred_backend = "spotify" })
            backend.invalidate_cache()

            backend.get_now_playing(function(track)
                result = track
            end)
            assert.equal("Spotify Song", result.name)
        end)
    end)

    describe("get_now_playing fallback", function()
        it("returns nil when backend returns nil and no alternative is available", function()
            config.apply({ preferred_backend = "apple_music" })
            -- Make apple_music return nil (nothing playing)
            mock_apple.get_now_playing = function(cb)
                cb(nil)
            end
            local backend = require("music.backend")
            local result = "not_called"

            backend.get_now_playing(function(track)
                result = track
            end)

            -- When apple_music returns nil and auto-detect re-runs,
            -- since preferred_backend is apple_music, it will get the same backend
            -- and cb(nil) should be called
            assert.is_nil(result)
        end)

        it("returns track data when backend has a track", function()
            config.apply({ preferred_backend = "spotify" })
            local backend = require("music.backend")
            local result

            backend.get_now_playing(function(track)
                result = track
            end)

            assert.is_not_nil(result)
            assert.equal("Spotify Song", result.name)
            assert.equal("https://example.com/art.jpg", result.art_url)
        end)
    end)

    describe("does not error when no backend available", function()
        it("calls cb(nil) when backend is nil", function()
            config.apply({ preferred_backend = "apple_music" })
            -- Replace apple_music with a backend that returns nil
            package.loaded["music.apple_music"] = make_mock_backend("apple_music", nil)
            local backend = require("music.backend")
            local result = "not_called"

            backend.get_now_playing(function(track)
                result = track
            end)

            assert.is_nil(result)
        end)
    end)
end)
