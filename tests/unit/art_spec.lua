describe("art", function()
    local art

    before_each(function()
        -- Force re-require to reset cache between tests
        package.loaded["music.art"] = nil
        art = require("music.art")
    end)

    describe("get_lines", function()
        it("returns empty table for nil url", function()
            assert.same({}, art.get_lines(nil, 30))
        end)

        it("returns cached result on second call with same url", function()
            -- Stub vim.fn.executable to report chafa as available
            local orig_executable = vim.fn.executable
            local orig_system = vim.fn.system
            local orig_systemlist = vim.fn.systemlist
            local orig_tempname = vim.fn.tempname
            local orig_delete = vim.fn.delete

            vim.fn.executable = function()
                return 1
            end
            vim.fn.system = function() end
            vim.fn.systemlist = function()
                return { "art_line_1", "art_line_2" }
            end
            vim.fn.tempname = function()
                return "/tmp/test_art"
            end
            vim.fn.delete = function()
                return 0
            end

            local first = art.get_lines("http://example.com/art.jpg", 30)
            local second = art.get_lines("http://example.com/art.jpg", 30)
            assert.same(first, second)

            vim.fn.executable = orig_executable
            vim.fn.system = orig_system
            vim.fn.systemlist = orig_systemlist
            vim.fn.tempname = orig_tempname
            vim.fn.delete = orig_delete
        end)
    end)

    describe("get_lines_from_file", function()
        it("returns empty table for nil path", function()
            assert.same({}, art.get_lines_from_file(nil, 30))
        end)

        it("returns cached result on second call with same path", function()
            local orig_executable = vim.fn.executable
            local orig_systemlist = vim.fn.systemlist

            vim.fn.executable = function()
                return 1
            end
            vim.fn.systemlist = function()
                return { "art_line_1" }
            end

            local first = art.get_lines_from_file("/tmp/test.jpg", 30)
            local second = art.get_lines_from_file("/tmp/test.jpg", 30)
            assert.same(first, second)

            vim.fn.executable = orig_executable
            vim.fn.systemlist = orig_systemlist
        end)

        it("shows install message when chafa is not available", function()
            local orig_executable = vim.fn.executable
            vim.fn.executable = function()
                return 0
            end

            local lines = art.get_lines_from_file("/tmp/test.jpg", 30)
            assert.equal(1, #lines)
            assert.truthy(lines[1]:find("install chafa"))

            vim.fn.executable = orig_executable
        end)

        it("shows art unavailable when chafa returns empty output", function()
            local orig_executable = vim.fn.executable
            local orig_systemlist = vim.fn.systemlist

            vim.fn.executable = function()
                return 1
            end
            vim.fn.systemlist = function()
                return {}
            end

            local lines = art.get_lines_from_file("/tmp/test.jpg", 30)
            assert.equal(1, #lines)
            assert.truthy(lines[1]:find("art unavailable"))

            vim.fn.executable = orig_executable
            vim.fn.systemlist = orig_systemlist
        end)

        it("prepends two-space indent to each line", function()
            local orig_executable = vim.fn.executable
            local orig_systemlist = vim.fn.systemlist

            vim.fn.executable = function()
                return 1
            end
            vim.fn.systemlist = function()
                return { "line1", "line2" }
            end

            local lines = art.get_lines_from_file("/tmp/test.jpg", 30)
            assert.equal("  line1", lines[1])
            assert.equal("  line2", lines[2])

            vim.fn.executable = orig_executable
            vim.fn.systemlist = orig_systemlist
        end)
    end)

    describe("clear_cache", function()
        it("clears all cached entries", function()
            local orig_executable = vim.fn.executable
            local orig_systemlist = vim.fn.systemlist
            local call_count = 0

            vim.fn.executable = function()
                return 1
            end
            vim.fn.systemlist = function()
                call_count = call_count + 1
                return { "line" .. call_count }
            end

            art.get_lines_from_file("/tmp/a.jpg", 30)
            assert.equal(1, call_count)

            -- Second call should be cached
            art.get_lines_from_file("/tmp/a.jpg", 30)
            assert.equal(1, call_count)

            -- Clear cache, should call chafa again
            art.clear_cache()
            art.get_lines_from_file("/tmp/a.jpg", 30)
            assert.equal(2, call_count)

            vim.fn.executable = orig_executable
            vim.fn.systemlist = orig_systemlist
        end)
    end)
end)
