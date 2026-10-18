function dashboard_template_path()
    return joinpath(@__DIR__, "dashboard_template.html")
end

function escape_html_attribute(text::AbstractString)
    return replace(text, "&" => "&amp;", "\"" => "&quot;", "<" => "&lt;", ">" => "&gt;")
end

# the output folder is <case>/results, so the case is named after the folder above it
function case_name(output_path::String)
    full_path = abspath(output_path)
    full_path = rstrip(full_path, ['/', '\\'])
    case_path = dirname(full_path)
    return basename(case_path)
end

# the CSV files are embedded as text in the page, so it opens offline with a double click and needs no server
function write_dashboard(output_path::String)
    name = case_name(output_path)
    case_attribute = escape_html_attribute(name)

    io = IOBuffer()
    for file_name in readdir(output_path)
        if !endswith(file_name, ".csv")
            continue
        end
        content = read(joinpath(output_path, file_name), String)
        file_attribute = escape_html_attribute(file_name)
        println(io, "<script type=\"text/csv\" data-case=\"$case_attribute\" data-file=\"$file_attribute\">")
        print(io, content)
        println(io, "</script>")
    end
    data_blocks = String(take!(io))

    template = read(dashboard_template_path(), String)
    page = replace(template, "<!-- nsLFT:CASE_DATA -->" => data_blocks)
    write(joinpath(output_path, "dashboard.html"), page)
    return nothing
end
