function read_column(file_path::String, column_name::String)
    lines = readlines(file_path)
    header = split(lines[1], ",")
    column_idx = findfirst(==(column_name), header)
    if column_idx === nothing
        error("Column $column_name not found in $file_path.")
    end

    values = String[]
    for line in lines[2:end]
        if isempty(strip(line))
            continue
        end
        push!(values, String(split(line, ",")[column_idx]))
    end
    return values
end

read_numbers(file_path::String, column_name::String) = parse.(Float64, read_column(file_path, column_name))

read_integers(file_path::String, column_name::String) = parse.(Int, read_column(file_path, column_name))
