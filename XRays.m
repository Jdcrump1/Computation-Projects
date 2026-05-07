% Adjusted MATLAB script for the new parameters

% New parameters based on provided info
tube_mAs = 10;                   % Tube current in mAs
filter_thickness_Al = 3;     % Aluminum filter thickness in mm
bone_thickness = 5;          % Bone thickness in cm
bone_density = 0.16;         % Bone density in g/cm^3
tissue_thickness = 20;       % Tissue thickness in cm
tissue_density = 1.06;       % Tissue density in g/cm^3
source_to_object_distance = 100; % Source-to-object distance in cm
pixel_size = 0.6;    % Detector pixel size in mm





% Load the X-ray spectrum data
load('/Users/jayc/Downloads/ebme410-computer-project-x-ray-1-new/Spectrum_100KVp.mat');
energy = KeV; % Assuming energy is in keV
spectrum = Spectrum; % Assuming spectrum is photon fluence

% Scale spectrum by mAs (proportional to number of photons)
Spectrum_scaled = spectrum * tube_mAs;







% Part  (a) - Plot the unfiltered X-ray spectrum
energy = 1:150;  % Energy levels (keV)

figure;
plot(KeV, Spectrum_scaled);
xlabel('Energy (KeV)');
ylabel('Photons');
title('Unfiltered X-ray Spectrum (Scaled by 10 mAs)');
grid on;

% Part (b) - Apply 3 mm Aluminum filter


attenuated_spectrum_Al = Spectrum_scaled .* exp(-muAl * filter_thickness_Al);

figure;
plot(KeV, attenuated_spectrum_Al);
xlabel('Energy (keV)');
ylabel('Photons');
title('X-ray Spectrum after 3mm Aluminum Filter');
grid on;

% Compute mean energy after aluminum filter
mean_energy_Al = sum(attenuated_spectrum_Al .* KeV') / sum(attenuated_spectrum_Al);
disp(['Mean Energy with 3mm Aluminum filter: ', num2str(mean_energy_Al), ' KeV']);
mean(attenuated_spectrum_Al)
% Part (c) - Pass the unfiltered spectrum through 20 cm of soft tissue
% Adjust the attenuation for tissue density

attenuation_tissue = muTissue * tissue_density;
attenuated_spectrum_tissue = Spectrum_scaled .* exp(-attenuation_tissue * tissue_thickness);

figure;
plot(KeV, attenuated_spectrum_tissue);
xlabel('Energy (keV)');
ylabel('Photons');
title('X-ray Spectrum after 20 cm Soft Tissue');
grid on;



% Compute mean energy after passing through soft tissue
mean_energy_tissue = sum(attenuated_spectrum_tissue .* KeV') / sum(attenuated_spectrum_tissue);
disp(['Mean Energy after passing through soft tissue: ', num2str(mean_energy_tissue), ' KeV']);

% Part (d) - Filtered spectrum through 20 cm of soft tissue
filtered_through_tissue = attenuated_spectrum_Al .* exp(-attenuation_tissue * tissue_thickness);

figure;
plot(KeV, filtered_through_tissue);
xlabel('Energy (keV)');
ylabel('Photon Count');
title('Filtered X-ray Spectrum after passing through 20 cm Soft Tissue');
grid on;


% Compute mean energy for filtered spectrum through tissue
mean_energy_filtered_tissue = sum(filtered_through_tissue .* KeV') / sum(filtered_through_tissue);
disp(['Mean Energy of filtered spectrum after passing through soft tissue: ', num2str(mean_energy_filtered_tissue), ' keV']);

% Part (e) - Effect of aluminum filter
% You can analyze the beam hardening effect by comparing the energy shift.






% Part 2 - Imaging with ideal photon counting detector

% (a) Pass through soft tissue and bone
attenuation_bone = muBone * bone_density;  % Adjust bone attenuation for density

% Soft tissue only
filtered_spectrum_soft_tissue = attenuated_spectrum_Al .* exp(-attenuation_tissue * tissue_thickness);

% Soft tissue + bone path
filtered_spectrum_bone = filtered_spectrum_soft_tissue .* exp(-attenuation_bone * bone_thickness);

% Plot soft tissue vs. soft tissue + bone filtered spectrum
figure;
plot(KeV, filtered_spectrum_soft_tissue, 'b', KeV, filtered_spectrum_bone, 'r');
xlabel('Energy (keV)');
ylabel('Photon Count');
title('Spectrum after passing through soft tissue vs soft tissue + bone');
legend('Soft Tissue', 'Soft Tissue + Bone');
grid on;
saveas(gcf, fullfile('/Users/jayc/Desktop/projectfigures', 'Attenuated_Spectrum_BT_100.jpg'))


% (b) Compute intensities detected by the ideal detector
% Integrating the spectrum to get total photon count
intensity_soft_tissue = trapz(KeV, filtered_spectrum_soft_tissue);
intensity_bone = trapz(KeV, filtered_spectrum_bone);
fprintf('Intensity of Soft Tissue: %.4f\n', intensity_soft_tissue);
fprintf('Intensity of Bone: %.4f\n', intensity_bone);

% Create a synthetic image where each pixel is associated with the mean x-ray intensity
% Assuming detector pixel size is 0.6 mm x 0.6 mm

% Image dimensions ( 128x128 pixels)
image_size = 128;
image = ones(image_size) * intensity_soft_tissue;

% Introduce a bone structure in the center of the image
bone_region = 30:70;  % Central region of the image contains bone
image(bone_region, bone_region) = intensity_bone;

% Scale the image to have a soft tissue pixel gray level of 128
max_gray_level = 256;
scaled_image = (image / intensity_soft_tissue) * 128;

% Display the image
figure;
imshow(uint8(scaled_image), [0 max_gray_level]);
set(gcf, 'Position', [100, 100, 800, 800]);
title('Simulated X-ray Image with Soft Tissue and Bone');
saveas(gcf, fullfile('/Users/jayc/Desktop/projectfigures', 'GrayImage_100.jpg'))

% Plot a row of pixels through the center of the image
figure;
% Extract the row from the center of the scaled image
center_row = scaled_image(image_size/2, :);

% Display the row of pixels as an image (instead of line plot)
imshow(repmat(center_row, [10 1]), [0 max_gray_level]); % Replicate the row for better visualization
xlabel('Pixel Index');
set(gcf, 'Position', [100, 100, 800, 800]);
ylabel('Gray Level');
title('Profile of Pixel Intensities through Center of the Image');
saveas(gcf, fullfile('/Users/jayc/Desktop/projectfigures', 'RowOfPixels_100.jpg'));



%%Part 4



% Calculate contrast based on intensities
contrast = abs((intensity_soft_tissue - intensity_bone) / (intensity_soft_tissue + intensity_bone));

% Display contrast
disp(['Contrast between soft tissue and bone: ', num2str(contrast)]);


%%Part 5


