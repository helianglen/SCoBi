
function plotNBRCS_vsTH_PH


%% ANALYSIS INPUTS
inputFile_sys_tag = 'sysInput-CORN_PAPER-row0';
inputFile_veg_tag = 'vegVirRowInput-CORN_PAPER-row0';

cornStagesStruct = struct('s1', 'V1_V9', ...
                            's2', 'V10_VT', ...
                            's3', 'R1_R4', ...
                            's4', 'R5', ...
                            's5', 'R6') ;


%% Choices
% TO-DO: Check here
stage_choice = cornStagesStruct.s3;
FZ_choice = 1 ;
SM_choice = 3 ;
RMSH_choice = 2 ;


%% GET INPUT
% Just for getting the initial values of some parameters
inputFile_sys = strcat( inputFile_sys_tag, '.xml' );
inputFile_veg = strcat( inputFile_veg_tag, '-', stage_choice, '.xml' );

getInput( inputFile_sys, inputFile_veg );

% Initialize but not create simulations' directories
SimulationFolders.getInstance.initializeStaticDirs();
% [isInputValid, isTerminate, terminateMsg] = ParamsManager.isInputValid();


%% GET GLOBAL PARAMETERS
% Simulation Parameters
Nfz = SimParams.getInstance.Nfz;
% Dynamic Parameters
th0_Tx_list_deg = DynParams.getInstance.th0_Tx_list_deg ;
num_Th = length( th0_Tx_list_deg );
ph0_Tx_list_deg = DynParams.getInstance.ph0_Tx_list_deg ;
num_Ph = length( ph0_Tx_list_deg );
VSM_list_cm3cm3 = DynParams.getInstance.VSM_list_cm3cm3 ;
RMSH_list_cm = DynParams.getInstance.RMSH_list_cm ;

    
%% NBRCS
% Initialization
PP1_inc_dB = zeros(2, 2, num_Th, num_Ph) ; % % PP1_inc1_dB = zeros(2, 2, num_Th) ; 
% % PP1_inc2_dB = zeros(2, 2, num_Th) ; PP1_inc3_dB = zeros(2, 2, num_Th) ; PP1_inc4_dB = zeros(2, 2, num_Th) ;
PP1_inc_dB2 = zeros(2, 2, Nfz, num_Th, num_Ph) ;

KKi_dB = zeros(num_Th, num_Ph) ;
P1_areas_dB = zeros(num_Th, num_Ph) ;
P1_areas_dB2 = zeros(Nfz, num_Th, num_Ph) ;


%% REFLECTIVITY
% Initilization
% over vegetation
P_cohveg_dB = zeros(2, 2, num_Th, num_Ph) ;
% over bare soil
P_cohbare_dB = zeros(2, 2, num_Th, num_Ph) ;

KKc_dB = zeros(num_Th, num_Ph) ;


%% READ
for pp = 1 : num_Ph
    
    % Set phi index
    ParamsManager.index_Ph( pp );
    
    for tt = 1 : num_Th
              
        % Set theta index
        ParamsManager.index_Th( tt );
        
        % Assign the index of interest to each, in this analysis
        ParamsManager.index_VSM( SM_choice );
        ParamsManager.index_RMSH( RMSH_choice );
        
        % Initialize the directories depending on theta phi, VSM, and RMSH
        SimulationFolders.getInstance.initializeDynamicDirs();
        
        
        %% GET GLOBAL DIRECTORIES
        dir_config = SimulationFolders.getInstance.config;
        dir_freqdiff = SimulationFolders.getInstance.freqdiff;
        dir_out_diffuse_P1_tuple = SimulationFolders.getInstance.out_diffuse_P1_tuple;
        dir_out_specular = SimulationFolders.getInstance.out_specular;
        
        
        %% NBRCS
        % read Ki
        filename1 = strcat('Ki') ;
        Ki = readComplexVar( dir_freqdiff, filename1) ;
        KKi_dB(tt, pp) = 10 * log10(abs(Ki) ^ 2 / 4 / pi) ;
        
        % Fresnel ellipses
        filenamex = 'ellipses_FZ_m' ;
        ellipses_FZ_m = readVar( dir_config, filenamex) ;
        areas_FZ_m = pi * ellipses_FZ_m(:, 1) .* ellipses_FZ_m(:, 2) ;
        P1_areas_dB(tt, pp) = 10 * log10(areas_FZ_m(FZ_choice)) ;
        P1_areas_dB2(:, tt, pp) = 10 * log10(areas_FZ_m) ;
        
        % transmit port 1 / receiver ports 1&2
        xx = readVar(dir_out_diffuse_P1_tuple, 'PP1_inc_t1_dB') ;
        PP1_inc_dB(1, :, tt, pp) = squeeze(xx(:, FZ_choice)) ;
        PP1_inc_dB2(1, :, :, tt, pp) = xx;
        
        % transmit port 2 / receiver ports 1&2
        xx = readVar(dir_out_diffuse_P1_tuple, 'PP1_inc_t2_dB') ;
        PP1_inc_dB(2, :, tt, pp) = squeeze(xx(:, FZ_choice)) ;
        PP1_inc_dB2(2, :, :, tt, pp) = xx;
        
        
        %% REFLECTIVITY        
        % read Kc
        filename1 = strcat('Kc') ;
        Kc = readComplexVar( dir_out_specular, filename1) ;
        KKc_dB(tt, pp) = 20 * log10(abs(Kc)) ;
        
        [~, ~, ~, ~, ~, ~, ~, ~, ...
            P_coh1vegx, P_coh2vegx, ~, ~, ...
            P_coh1barex, P_coh2barex, ~, ~] = readSpecular ;
        
        P_cohveg_dB(1, :, tt, pp) = 10 * log10( P_coh1vegx(1 : 2) ) + KKc_dB(tt) ;
        P_cohveg_dB(2, :, tt, pp) = 10 * log10( P_coh2vegx(1 : 2) ) + KKc_dB(tt) ;
        
        P_cohbare_dB(1, :, tt, pp) = 10 * log10( P_coh1barex(1 : 2) ) + KKc_dB(tt) ;
        P_cohbare_dB(2, :, tt, pp) = 10 * log10( P_coh2barex(1 : 2) ) + KKc_dB(tt) ;
        
    end

    if pp == 1
        dir_analysis = SimulationFolders.getInstance.analysis;
        if ~exist(dir_analysis, 'dir')
            mkdir(dir_analysis)
        end
    end

end

%% Normalization
NBRCS_dB_TOT = 10 * log10(10.^(P_cohveg_dB/10) + 10.^(PP1_inc_dB/10)) ...
    - reshape(repmat(KKi_dB, 4, 1), 2, 2, num_Th, num_Ph) ...
    - reshape(repmat(P1_areas_dB, 4, 1), 2, 2, num_Th, num_Ph) ; 
NBRCS_dB = PP1_inc_dB ...
    - reshape(repmat(KKi_dB, 4, 1), 2, 2, num_Th, num_Ph) ...
    - reshape(repmat(P1_areas_dB, 4, 1), 2, 2, num_Th, num_Ph) ; 

REFL_dB_TOT = 10 * log10(10.^(P_cohveg_dB/10) + 10.^(PP1_inc_dB/10)) - reshape(repmat(KKc_dB, 4, 1), 2, 2, num_Th, num_Ph) ; 
REFL_dB = P_cohveg_dB - reshape(repmat(KKc_dB, 4, 1), 2, 2, num_Th, num_Ph) ; 





% TO-DO: Check this
%% GET GLOBAL PARAMETERS
% Transmitter Parameters
pol_Tx = TxParams.getInstance.pol_Tx;
% Receiver Parameters
pol_Rx = RxParams.getInstance.pol_Rx;
% Dynamic Parameters
ph0_Tx_list_deg = DynParams.getInstance.ph0_Tx_list_deg;
ph0_Tx_deg = ph0_Tx_list_deg( ParamsManager.index_Ph );
VSM_cm3cm3 = DynParams.getInstance.VSM_list_cm3cm3( ParamsManager.index_VSM );
RMSH_cm = DynParams.getInstance.RMSH_list_cm( ParamsManager.index_RMSH );
% Vegetation Parameters
vegetation_stage = VegParams.getInstance.vegetation_stage;


%% FIGURES
markerSymbol_RL = {'-^b', '-vb', '-ob', '-sb', '-db'};
markerSymbol_RR = {'-^r', '-vr', '-or', '-sr', '-dr'};

% Total NBRCS vs TH
for pp = 1 : num_Ph
    
    NBRCS_dB_RR(:, pp) = squeeze(NBRCS_dB(1, 1, :, pp)) ;
    NBRCS_dB_RL(:, pp) = squeeze(NBRCS_dB(1, 2, :, pp)) ;
    
    if pp == 1
        
        figure 
        
%         subplot(1,2,1)
        hold
        axis([0 80 -25 -10])
        xlabel('\theta_s [\circ]')
        ylabel('\sigma^0_e [dB]')
        xticks(th0_Tx_list_deg(1) : 10 : th0_Tx_list_deg(end))
        grid
        ph0_Tx_list_deg_str = sprintf('%d,' , ph0_Tx_list_deg);
        ph0_Tx_list_deg_str = ph0_Tx_list_deg_str( 1 : end-1 );% strip final comma
        text(53, -11, strcat( '\phi_s=\{', ph0_Tx_list_deg_str, '\}\circ' ), 'Interpreter', 'tex')
        text(53, -12.5, strcat( 'VSM=', num2str( VSM_list_cm3cm3(SM_choice) ), ' cm^3/cm^3' ))
        text(53, -14, strcat( 'RMSH=', num2str( RMSH_list_cm(RMSH_choice) ), ' cm' ))
        text(53, -15.5, strcat('fzone=1'))
        text(3, NBRCS_dB_RL(1,1), strcat('RL'))
        text(3, NBRCS_dB_RR(1,1), strcat('RR'))
        title('NBRCS Variations due to Corn Row Orientation')
        
%         subplot(1,2,2)
%         hold
%         axis([0 80 -20 -10])
%         xlabel('\theta_s [\circ]')
%         %ylabel('\sigma^0_e [dB]')
%         xticks(th0_Tx_list_deg(1) : 10 : th0_Tx_list_deg(end))
%         grid
%         %text(20, -10, strcat( num2str( ph0_Tx_list_deg(1) ), '\circ \leq \phi_r_o_w \leq ', num2str( ph0_Tx_list_deg(end) ), '\circ' ), 'Interpreter', 'tex')
%         %text(45, 20, strcat('fzone = 1'))
%         title('NBRCS Variations due to Corn Row Orientation')
    end
    
%     subplot(1,2,1)
    plot(th0_Tx_list_deg, NBRCS_dB_RL(:, pp), markerSymbol_RL{pp}, 'MarkerFaceColor', 'blue', 'MarkerSize', 5)
%     subplot(1,2,2)
    plot(th0_Tx_list_deg, NBRCS_dB_RR(:, pp), markerSymbol_RR{pp}, 'MarkerFaceColor', 'red', 'MarkerSize', 5)

end


fname = strcat('NBRCS_vs_TH_PH-', vegetation_stage, '-', pol_Tx, pol_Rx, '-FZ_', num2str(FZ_choice), '-PH_', num2str( ph0_Tx_deg ), '-VSM_', num2str( VSM_cm3cm3 ), '-RMSH_', num2str( RMSH_cm ) ) ;
fname = strrep( fname, '.', 'dot' );

saveas(gcf, strcat(dir_analysis, '\', fname), 'tiff')
close



%% WITH ERRORBAR
figure      
hold
axis([0 80 -20 -10])
xlabel('\theta_s [\circ]')
ylabel('\sigma^0_e [dB]')
xticks(th0_Tx_list_deg(1) : 10 : th0_Tx_list_deg(end))
grid
ph0_Tx_list_deg_str = sprintf('%d,' , ph0_Tx_list_deg);
ph0_Tx_list_deg_str = ph0_Tx_list_deg_str( 1 : end-1 );% strip final comma
text(53, -11, strcat( '\phi_r_o_w = \{', ph0_Tx_list_deg_str, '\}\circ' ), 'Interpreter', 'tex')
text(53, -12, strcat( 'VSM=', num2str( VSM_list_cm3cm3(SM_choice) ), ' cm^3/cm^3' ))
text(53, -13, strcat( 'RMSH=', num2str( RMSH_list_cm(RMSH_choice) ), ' cm' ))
text(53, -14, strcat('fzone = 1'))
text(3, -14, strcat('RL'))
text(3, -19, strcat('RR'))
title('NBRCS Variations due to Corn Row Orientation')
        
for tt = 1 : num_Th

    NBRCS_dB_RL_mean(tt) = mean( NBRCS_dB_RL(tt,:) );
    NBRCS_dB_RL_pos(tt) = max( NBRCS_dB_RL(tt,:) ) - NBRCS_dB_RL_mean(tt);
    NBRCS_dB_RL_neg(tt) = NBRCS_dB_RL_mean(tt) - min( NBRCS_dB_RL(tt,:) );

    NBRCS_dB_RR_mean(tt) = mean( NBRCS_dB_RR(tt,:) );
    NBRCS_dB_RR_pos(tt) = max( NBRCS_dB_RR(tt,:) ) - NBRCS_dB_RR_mean(tt);
    NBRCS_dB_RR_neg(tt) = NBRCS_dB_RR_mean(tt) - min( NBRCS_dB_RR(tt,:) );

end

errorbar( th0_Tx_list_deg, NBRCS_dB_RL_mean, NBRCS_dB_RL_pos, NBRCS_dB_RL_neg,'-s','MarkerSize',5,...
    'MarkerEdgeColor','blue','MarkerFaceColor','blue');
errorbar( th0_Tx_list_deg, NBRCS_dB_RR_mean, NBRCS_dB_RR_pos, NBRCS_dB_RR_neg,'-s','MarkerSize',5,...
    'MarkerEdgeColor','red','MarkerFaceColor','red');


fname = strcat('NBRCS_vs_rowPH-errorbar-', vegetation_stage, '-RR-FZ_', num2str(FZ_choice), '-', pol_Tx, pol_Rx, '-PH_', num2str( ph0_Tx_deg ), '-VSM_', num2str( VSM_cm3cm3 ), '-RMSH_', num2str( RMSH_cm ) ) ;
fname = strrep( fname, '.', 'dot' );

% saveas(gcf, strcat(dir_analysis, '\', fname), 'tiff')
close


end