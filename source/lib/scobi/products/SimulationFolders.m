classdef SimulationFolders < handle
    % SIMULATIONFOLDERS Class to keep track of all output directories
    %   This class has one attribute for each source code or input
    %   directory. Every attribute can be reached by a static getter method.
    
    
properties (SetAccess = private, GetAccess = public)


    sims_main_dir    

    
    %% ANALYSIS
    analysis


    % OUTPUT
    output
    sim

    % Input
    sim_input
    sim_input_used_files

    % Metadata
    metadata
    afsa

    % Products
    products
    products_direct
    products_direct_field
    products_direct_power
    products_specular
    products_specular_reff_coeff
    products_specular_reff_coeff_diel_profiles
    products_specular_reflectivity
    products_specular_reflectivity_diel_profiles

    % Figures
    fig
    fig_direct
    fig_specular
    fig_specular_reflectivity
    fig_specular_reflectivity_vsTH

end
    
    
methods (Access = private)

    function obj = SimulationFolders
    end

    end


    methods (Static)

    function singleObj = getInstance
    persistent localObj

    if isempty(localObj) || ~isvalid(localObj)
       localObj = SimulationFolders;
    end

     singleObj = localObj;
    end
    end
        
    
methods
        
    function initializeStaticDirs(obj)


    %% GET GLOBAL DIRECTORIES
    main_dir = Directories.getInstance.main_dir;


    %% GET GLOBAL PARAMETERS
    % Simulation Settings
    sim_name = SimSettings.getInstance.sim_name;
    include_in_master_sim_file = SimSettings.getInstance.include_in_master_sim_file;
    gnd_cover_id = SimSettings.getInstance.gnd_cover_id;


    %% INITIALIZE DIRECTORIES
    % Initialize static simulation directories
    if include_in_master_sim_file

        obj.sims_main_dir = strcat( main_dir, '\sims\master');

    else

        obj.sims_main_dir = strcat( main_dir, '\sims\temp');
    end


    %% ANALYSIS
    obj.analysis = strcat( obj.sims_main_dir, '\', 'analysis') ; 


    %% OUTPUT
    obj.output = strcat( obj.sims_main_dir , '\output');

    % TO-DO: create a unique name with timestamp
    obj.sim = strcat( obj.output, '\', sim_name);

    % Simulation input
    obj.sim_input = strcat( obj.sim, '\input');
    obj.sim_input_used_files = strcat( obj.sim_input, '\used_files');

    % Meta-Data
    obj.metadata = strcat( obj.sim, '\metadata');

    % Average Forward Scattering Amplitude
    if gnd_cover_id == Constants.id_veg_cover
    
        obj.afsa = strcat(obj.metadata, '\', 'afsa');  
        
    end

    % Products
    obj.products = strcat(obj.sim, '\', 'products') ;
    obj.products_direct = strcat(obj.products, '\', 'direct') ;
    obj.products_direct_field = strcat(obj.products_direct, '\', 'field') ;
    obj.products_direct_power = strcat(obj.products_direct, '\', 'power') ;
    obj.products_specular = strcat(obj.products, '\', 'specular') ;
    obj.products_specular_reff_coeff = strcat(obj.products_specular, '\', 'reflection_coefficient') ;
    obj.products_specular_reflectivity = strcat(obj.products_specular, '\', 'reflectivity') ;
    
    % Products for multiple dielectric profiles
    diel_profiles = Constants.diel_profiles;
    [~, num_diel_profiles] = size( diel_profiles );
    
    for ii = 1 : num_diel_profiles
        
        current_diel_profile = diel_profiles{1, ii};
        obj.products_specular_reff_coeff_diel_profiles{1, ii}  = strcat(obj.products_specular_reff_coeff, '\', current_diel_profile );
        obj.products_specular_reflectivity_diel_profiles{1, ii}  = strcat(obj.products_specular_reflectivity, '\', current_diel_profile );
        
    end
        

    % Figure
    obj.fig = strcat(obj.sim, '\', 'figure' ) ;
    obj.fig_direct = strcat(obj.fig, '\', 'direct') ;
    obj.fig_specular = strcat(obj.fig, '\', 'specular') ;
    obj.fig_specular_reflectivity = strcat(obj.fig_specular, '\', 'reflectivity') ;
    obj.fig_specular_reflectivity_vsTH = strcat(obj.fig_specular_reflectivity, '\', 'vs_TH') ;


    end


    function makeStaticDirs(obj)


        %% Simulations main directory
        if ~exist(obj.sims_main_dir, 'dir')
            mkdir(obj.sims_main_dir);
        end


        %% Analysis
        if ~exist(obj.analysis, 'dir')
            mkdir(obj.analysis);
        end

        %% Input folder that includes sim. report and input file used
        if ~exist(obj.sim_input, 'dir')
            mkdir(obj.sim_input)
        end

        %% Input folder that contains the used input files for the sim.
        if ~exist(obj.sim_input_used_files, 'dir')
            mkdir(obj.sim_input_used_files)
        end

        %% Average Forward Scattering Amplitude
        if ~exist(obj.afsa, 'dir')
            mkdir(obj.afsa)
        end

        %% Products
        if ~exist(obj.products, 'dir')
            mkdir(obj.products)
        end

        if ~exist(obj.products_direct, 'dir')
            mkdir(obj.products_direct)
        end

        if ~exist(obj.products_direct_field, 'dir')
            mkdir(obj.products_direct_field)
        end

        if ~exist(obj.products_direct_power, 'dir')
            mkdir(obj.products_direct_power)
        end

        if ~exist(obj.products_specular, 'dir')
            mkdir(obj.products_specular)
        end

        if ~exist(obj.products_specular_reff_coeff, 'dir')
            mkdir(obj.products_specular_reff_coeff)
        end

        if ~exist(obj.products_specular_reflectivity, 'dir')
            mkdir(obj.products_specular_reflectivity)
        end
    
        % Products for multiple dielectric profiles
        diel_profiles = Constants.diel_profiles;
        [~, num_diel_profiles] = size( diel_profiles );

        for ii = 1 : num_diel_profiles

            if ~exist(obj.products_specular_reff_coeff_diel_profiles{1, ii}, 'dir')
            
                mkdir(obj.products_specular_reff_coeff_diel_profiles{1, ii})
            
            end

            if ~exist(obj.products_specular_reflectivity_diel_profiles{1, ii}, 'dir')
            
                mkdir(obj.products_specular_reflectivity_diel_profiles{1, ii})
            
            end
        
        end

        % Figure
        if ~exist(obj.fig, 'dir')
            mkdir(obj.fig)
        end

        if ~exist(obj.fig_direct, 'dir')
            mkdir(obj.fig_direct)
        end

        if ~exist(obj.fig_specular, 'dir')
            mkdir(obj.fig_specular)
        end

        if ~exist(obj.fig_specular_reflectivity, 'dir')
            mkdir(obj.fig_specular_reflectivity)
        end

        if ~exist(obj.fig_specular_reflectivity_vsTH, 'dir')
            mkdir(obj.fig_specular_reflectivity_vsTH)
        end

    end

    function out = get.sims_main_dir(obj)
        out = obj.sims_main_dir;
    end

    function out = get.analysis(obj)
        out = obj.analysis;
    end

    function out = get.sim(obj)
        out = obj.sim;
    end

    function out = get.sim_input(obj)
        out = obj.sim_input;
    end 

    function out = get.sim_input_used_files(obj)
        out = obj.sim_input_used_files;
    end 

    function out = get.afsa(obj)
        out = obj.afsa;
    end 

    function out = get.products_direct(obj)
        out = obj.products_direct;
    end

    function out = get.products(obj)
        out = obj.products;
    end

    function out = get.products_direct_field(obj)
        out = obj.products_direct_field;
    end

    function out = get.products_direct_power(obj)
        out = obj.products_direct_power;
    end

    function out = get.products_specular(obj)
        out = obj.products_specular;
    end

    function out = get.products_specular_reff_coeff(obj)
        out = obj.products_specular_reff_coeff;
    end

    function out = get.products_specular_reff_coeff_diel_profiles(obj)
        out = obj.products_specular_reff_coeff_diel_profiles;
    end

    function out = get.products_specular_reflectivity(obj)
        out = obj.products_specular_reflectivity;
    end

    function out = get.products_specular_reflectivity_diel_profiles(obj)
        out = obj.products_specular_reflectivity_diel_profiles;
    end

    function out = get.fig(obj)
        out = obj.fig;
    end

    function out = get.fig_direct(obj)
        out = obj.fig_direct;
    end

    function out = get.fig_specular(obj)
        out = obj.fig_specular;
    end

    function out = get.fig_specular_reflectivity(obj)
        out = obj.fig_specular_reflectivity;
    end

    function out = get.fig_specular_reflectivity_vsTH(obj)
        out = obj.fig_specular_reflectivity_vsTH;
    end
        
end
    
end
