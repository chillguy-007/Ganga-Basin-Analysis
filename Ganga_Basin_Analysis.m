% =========================================================================
% Ganga Basin Rainfall Analysis
% Author  : Rishit Bhardwaj (24JE0050)
% Purpose : Spatial filtering, trend analysis, and extreme-event detection
%           for the Ganga Basin using IMD 0.25° gridded daily rainfall data.
% Dataset : IMD High-Resolution 0.25° Daily Gridded Rainfall
% Files   : RF25ind<YEAR>_rfp25.nc  — one file per year; place in working
%           directory or add the data folder to the MATLAB path.
% =========================================================================

%% Data Import (Single-Year Bootstrap)

% *** SET YOUR DATA PATH ***
% Update 'filename' below (or add the data folder to the MATLAB path)
% before running this script on a new machine.
filename = 'RF25ind2024_rfp25.nc';

latitude  = ncread(filename, 'lat');
longitude = ncread(filename, 'lon');
time      = ncread(filename, 'time');

% IMD files use 'rf' in recent years; older files use 'RAINFALL' (handled below)
rainfall = ncread(filename, 'rf');

disp('Data import complete for RF25ind2024_rfp25.nc.');
disp('Check your workspace for the new variables.');

%% Spatial Filtering for Ganga Basin

% Bounding box in decimal degrees (converted from degrees/minutes)
min_lon = 73 + 2/60;   % 73°2'  E
max_lon = 89 + 5/60;   % 89°5'  E
min_lat = 21 + 6/60;   % 21°6'  N
max_lat = 31 + 21/60;  % 31°21' N

lon_indices = find(longitude >= min_lon & longitude <= max_lon);
lat_indices = find(latitude  >= min_lat & latitude  <= max_lat);

% Slice the 3-D array (lon, lat, time); ':' keeps all time steps
basin_rainfall = rainfall(lon_indices, lat_indices, :);

% Coordinate vectors aligned to the basin slice (needed for plot axes)
basin_lon = longitude(lon_indices);
basin_lat = latitude(lat_indices);

disp('Spatial filtering complete.');
disp('Size of the new basin_rainfall matrix:');
disp(size(basin_rainfall));

%% Multi-Year Data Loading

start_year = 2015;
end_year   = 2024;
years      = start_year:end_year;

basin_rainfall_multi_year = [];

fprintf('Loading data for years %d to %d...\n', start_year, end_year);

for year = years
    filename = sprintf('RF25ind%d_rfp25.nc', year);

    if exist(filename, 'file')
        fprintf('Processing %s...\n', filename);

        % Some IMD files use 'rf'; older releases use the all-caps 'RAINFALL'
        try
            full_rainfall_yearly = ncread(filename, 'rf');
        catch
            fprintf('     > Note: Using older variable name "RAINFALL".\n');
            full_rainfall_yearly = ncread(filename, 'RAINFALL');
        end

        basin_rainfall_yearly     = full_rainfall_yearly(lon_indices, lat_indices, :);
        basin_rainfall_multi_year = cat(3, basin_rainfall_multi_year, basin_rainfall_yearly);
    else
        fprintf('Warning: File %s not found. Skipping.\n', filename);
    end
end

disp('-------------------------------------------');
disp('Multi-year data loading complete.');
disp('Final matrix size (Lon x Lat x Time):');
disp(size(basin_rainfall_multi_year));

%% Daily Average Rainfall

disp('Calculating daily average rainfall across the basin (ignoring missing data)...');

[lon_count, lat_count, time_count] = size(basin_rainfall_multi_year);
reshaped_rainfall = reshape(basin_rainfall_multi_year, lon_count * lat_count, time_count);

% 'omitnan' is required: IMD files contain NaN fill values for ocean/missing cells
daily_avg_rainfall = mean(reshaped_rainfall, 1, 'omitnan');

figure;
plot(daily_avg_rainfall, 'y', 'LineWidth', 1.5);
title('Average Daily Rainfall in Ganga Basin (2015-2024)');
xlabel('Days (since start of 2015)');
ylabel('Average Rainfall (mm/day)');
grid on;

fprintf('Daily average rainfall calculated and plotted.\n');

%% Annual Totals & Leap-Year Handling

disp('Calculating total annual rainfall for trend analysis...');

years                 = start_year:end_year;
annual_total_rainfall = zeros(1, length(years));
day_index_start       = 1;

for i = 1:length(years)
    current_year  = years(i);
    days_in_year  = 365 + isLeap(current_year);
    day_index_end = day_index_start + days_in_year - 1;

    annual_total_rainfall(i) = sum(daily_avg_rainfall(day_index_start:day_index_end));
    day_index_start = day_index_end + 1;
end

figure;
bar(years, annual_total_rainfall);
title('Total Annual Rainfall in Ganga Basin (2015-2024)');
xlabel('Year');
ylabel('Total Rainfall (mm/year)');
grid on;

fprintf('Annual rainfall totals calculated and plotted.\n');

%% Trend Analysis — Linear Regression

disp('Performing linear regression on annual data...');

% p(1) = slope (mm/year per year), p(2) = intercept
p          = polyfit(years, annual_total_rainfall, 1);
trend_line = polyval(p, years);

figure;
bar(years, annual_total_rainfall);
hold on;
plot(years, trend_line, 'r-', 'LineWidth', 2);
hold off;

title('Total Annual Rainfall and Trend Line (2015-2024)');
xlabel('Year');
ylabel('Total Rainfall (mm/year)');
legend('Annual Total', 'Linear Trend');
grid on;

slope = p(1);
fprintf('Linear regression complete.\n');
fprintf('The slope of the trend line is: %f mm/year\n', slope);

%% Extreme Event Detection

disp('Identifying extreme rainfall events...');

extreme_threshold  = prctile(daily_avg_rainfall, 95);
total_extreme_days = sum(daily_avg_rainfall > extreme_threshold);

fprintf('Extreme rainfall threshold (95th percentile) is: %f mm/day\n', extreme_threshold);
fprintf('Total number of extreme rainfall days in 10 years: %d\n', total_extreme_days);

disp('Counting extreme rainfall days per year...');

yearly_extreme_counts = zeros(1, length(years));
day_index_start       = 1;

for i = 1:length(years)
    current_year  = years(i);
    days_in_year  = 365 + isLeap(current_year);
    day_index_end = day_index_start + days_in_year - 1;

    year_slice_data          = daily_avg_rainfall(day_index_start:day_index_end);
    yearly_extreme_counts(i) = sum(year_slice_data > extreme_threshold);
    day_index_start          = day_index_end + 1;
end

figure;
bar(years, yearly_extreme_counts);
title('Number of Extreme Rainfall Days Per Year (2015-2024)');
xlabel('Year');
ylabel('Count of Extreme Days (>95th Percentile)');
grid on;

fprintf('Annual counts of extreme days calculated and plotted.\n');

%% Spatial Heatmap

disp('Generating spatial heatmap of average rainfall...');

% Mean over time (dim 3); omitnan excludes ocean/fill cells
mean_rainfall_grid = mean(basin_rainfall_multi_year, 3, 'omitnan');

figure;
imagesc(basin_lon, basin_lat, mean_rainfall_grid');
% Transpose so latitude runs along the y-axis
set(gca, 'YDir', 'normal');  % North (higher latitude) up
colorbar;
title('10-Year Average Daily Rainfall Distribution in Ganga Basin');
xlabel('Longitude (°E)');
ylabel('Latitude (°N)');

%% 3D Surface Plot

disp('Generating 3D surface plot of average rainfall...');

% meshgrid requires 2-D matrix inputs; transpose Z to match X/Y orientation
[X, Y] = meshgrid(basin_lon, basin_lat);
Z = mean_rainfall_grid';

figure;
surf(X, Y, Z, 'EdgeColor', 'none');  % 'none' produces a smoother surface
xlabel('Longitude (°E)');
ylabel('Latitude (°N)');
zlabel('Average Daily Rainfall (mm/day)');
title('3D View of 10-Year Average Rainfall in Ganga Basin');
colorbar;
view(-45, 30);
grid on;

fprintf('3D surface plot generated.\n');

%% Rainfall Projection — Linear Model

disp('Projecting rainfall for future years based on the linear trend...');

future_years       = [2025, 2026, 2027];
predicted_rainfall = polyval(p, future_years);

fprintf('\n--- Rainfall Projections based on 2015-2024 Trend ---\n');
for i = 1:length(future_years)
    fprintf('Projected total rainfall for %d: %.2f mm/year\n', future_years(i), predicted_rainfall(i));
end
fprintf('-----------------------------------------------------\n');

figure;
hold on;
bar(years, annual_total_rainfall);
plot(years, trend_line, 'r-',  'LineWidth', 2);
plot(future_years, predicted_rainfall, 'r--', 'LineWidth', 2);
hold off;

title('Annual Rainfall with Trend Projection to 2027');
xlabel('Year');
ylabel('Total Rainfall (mm/year)');
legend('Annual Total', 'Historical Trend', 'Projected Trend');
grid on;

fprintf('Plot with trend projection generated.\n');

%% 2nd-Degree Polynomial Trend

disp('Fitting a 2nd-degree polynomial (curved) trend...');

p_poly2     = polyfit(years, annual_total_rainfall, 2);
fine_years  = linspace(min(years), max(years), 100);
trend_curve = polyval(p_poly2, fine_years);

figure;
bar(years, annual_total_rainfall);
hold on;
plot(fine_years, trend_curve, 'g-', 'LineWidth', 2);
hold off;

title('Annual Rainfall with a 2nd-Degree Polynomial Trend');
xlabel('Year');
ylabel('Total Rainfall (mm/year)');
legend('Annual Total', '2nd-Degree Polynomial Trend');
grid on;

fprintf('Plot with curved trend line generated.\n');

%% 2nd-Degree Polynomial Projection

disp('Projecting rainfall using the 2nd-degree polynomial model...');

future_years             = [2025, 2026, 2027];
predicted_rainfall_poly2 = polyval(p_poly2, future_years);

fprintf('\n--- Projections based on the 2nd-Degree Polynomial Trend ---\n');
for i = 1:length(future_years)
    fprintf('Projected total rainfall for %d: %.2f mm/year\n', future_years(i), predicted_rainfall_poly2(i));
end
fprintf('-----------------------------------------------------------\n');

all_years_fine   = linspace(min(years), max(future_years), 150);
full_trend_curve = polyval(p_poly2, all_years_fine);

figure;
hold on;
bar(years, annual_total_rainfall);
plot(all_years_fine, full_trend_curve, 'g-', 'LineWidth', 2);
hold off;

title('Annual Rainfall with 2nd-Degree Trend Projection to 2027');
xlabel('Year');
ylabel('Total Rainfall (mm/year)');
legend('Annual Total (Historical)', 'Polynomial Trend (Historical & Projected)');
grid on;

fprintf('Plot with curved trend projection generated.\n');

%% Local Functions

function result = isLeap(year)
% Returns 1 if year is a leap year under the Gregorian calendar, 0 otherwise
result = (mod(year, 4) == 0) && (mod(year, 100) ~= 0 || mod(year, 400) == 0);
end
