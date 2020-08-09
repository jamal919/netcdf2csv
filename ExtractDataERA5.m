% ExtractDataERA5 Extract ERA5 data to csv.
% 
% ExtractDataERA5(inputdir, outdir, bbox, startdate, var, multiplier,
% addition) extracts all netcdf files from input dir to the output dir for
% variable var. inputdir and outdir must be string of the path name.
% The startdate corresponds to the date unit in the netcdf
% file, and expected in the netcdf file as day since startdate. var is the
% variable name to be extracted. If any multiplier or addition to be
% performed on the datat those are provided in multiplier and addition
% parameter. bbox is the bounding box array in [West, East, South, North]
% format. 
%
% ExtractDataERA5(inputdir, outdir, [87, 93, 20, 26], '1900-01-01', 'tp', 1, 0)

function [status] = ExtractDataERA5(inputdir, outdir, bbox, startdate, var, multiplier, addition)

% Listing the files from the directory.
files = dir(fullfile(inputdir,'*.nc'));

% Showing the ncdisp of typical file
if ~isempty(files)
    ncdisp(fullfile(inputdir, files(1).name));
    % Loading Common values
    % Lat-lon is taken same for all values.
    file = fullfile(inputdir, files(1).name);
    disp(file);
    lon = ncread(file, 'longitude');
    lat = ncread(file, 'latitude');
end

% Start Date
% It can be found from the time definition of the input files.
start_date = datenum(startdate);

% lat-lon range of interest
lon_w = bbox(1);
lon_e = bbox(2);
lat_s = bbox(3);
lat_n = bbox(4);

% Here FindClosest finds the closest lat and lon that is actually in the
% file.
[lat_s, ~] = FindClosest(lat, lat_s);
[lat_n, ~] = FindClosest(lat, lat_n);
[lon_w, ~] = FindClosest(lon, lon_w);
[lon_e, ~] = FindClosest(lon, lon_e);

% Grid size is determined by subtracting the consequtive grid. 
% The grid is takes as structured and equally spaced.
grid_size = abs(lon(1) - lon(2));

% It is the variable name that is to be extracted. 
% The input must be a string. That is in single quote 'varName'
var_name = var;

% If data needs any multiplication change here
% It is for conversion of one unit to another.
multiplier = multiplier; 
addition = addition;

% creating output file name & open file for writing
outfile = fullfile(outdir, [var_name '.csv']); 
disp(['Files will be saved as - ', outfile]);

tic; % Keeping track of time.
% Create listing for lat-lon of interest
position = zeros(2, length(lon_w : grid_size : lon_e) * length(lat_s : grid_size : lat_n));
ly = lat_s : grid_size : lat_n;
lx = lon_w : grid_size : lon_e;
for i = 1 : length(ly)
    position(1, (i - 1)*length(lx) +1 : i * length(lx)) = ones(1, length(lx)) * ly(i);
    position(2, (i - 1)*length(lx) +1 : i * length(lx)) = lx;
end

% Create headers
headers = num2cell(position);
headers = [{'latitude';'longitude'} headers];
[row, col] = size(headers);

% Creating the format specifier
day_string = {'%s,'};
num_form = {'%f,'};
end_elem = {'%f\n'};
string_format = [day_string repelem(num_form, length(position)-1) end_elem];
string_format = cell2mat(string_format);

% Opening file for writing header in write mode
fid = fopen(outfile, 'w');
% Now writing header line by line using fprintf
for i = 1 : row
    fprintf(fid, string_format, headers{i, :});
end
fclose(fid);

% Opening file for writing data values
% This file will be closed at the end
fid = fopen(outfile, 'a');

% File iteration will be started here
% Iterate for file in files
for file_num = 1 : length(files)
    % Setting file name
    file = fullfile(inputdir, files(file_num).name);

    % Variables are time, var_name, lon, lat
    time = ncread(file, 'time');
    time = double(time);
    time = time/24; % convert hour to day
    var_value = ncread(file, var_name);
    % Reading the first reanalysis value
    var_value = var_value(:, :, 1, :); % 1 of 2
    lon = ncread(file, 'longitude'); 
    lat = ncread(file, 'latitude'); 

    % Temporary data storage 
    year_chunk = zeros(length(time), length(lon_w : grid_size : lon_e) * length(lat_s : grid_size : lat_n) + 1);
    year_chunk = num2cell(year_chunk);
    % Running loop to extract data
    dates = cellfun(@datestr, num2cell(time + start_date), 'UniformOutput', false);
    year_chunk(:, 1) = dates;
    for i = 1 : length(position)
        % pos is in latitude; longitude format in ith column
        varData = var_value(find(lon == position(2, i)), find(lat == position(1, i)), :) * multiplier + addition;
        % flattening prData
        varData = reshape(varData(1:length(time)), [length(time), 1]);
        year_chunk(:, i+1) = num2cell(varData);
    end

    % writing year_chunk
    [rows, cols] = size(year_chunk);
    for row = 1 : rows
        fprintf(fid, string_format, year_chunk{row, :});
    end
    
    % displaying completion message
    msg_comp = ['File ',num2str(file_num), ' of ', num2str(length(files)), ' - ', file, ' - ', 'Completed!'];
    disp(msg_comp);
end
fclose('all'); % closing all open files
