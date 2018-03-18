% Mehmet Kurm
% March 2, 2017

function antennaPatternMatrix

if RecParams.getInstance.SLL_dB == 15 ;
    a = 0.18 ; % 0.35 ;  % 15 dB    
elseif RecParams.getInstance.SLL_dB == 20 ;
    a = 0.11 ; % 0.25 ;  % 20 dB    
elseif RecParams.getInstance.SLL_dB == 30 ;
    a = 0.04 ; % 0.12 ;  % 30 dB    
elseif RecParams.getInstance.SLL_dB == 40 ;
    a = 0.01 ; % 0.055 ; % 40 dB    
end


% X-pol level
if RecParams.getInstance.XPL_dB == 15
    V = sqrt(0.0316) ; % -15 dB
elseif RecParams.getInstance.XPL_dB == 25
    V = sqrt(0.0100);  % -20 dB
elseif RecParams.getInstance.XPL_dB == 30
    V = sqrt(0.0010) ;  % -30 dB
elseif RecParams.getInstance.XPL_dB == 40
    V = sqrt(0.0001) ; % -40 dB
end

[th, ph, gg] = GGpattern(RecParams.getInstance.hpbw_deg, a) ;
gXX = gg ; gYY = gg ;

[~, ~, gg] = GGpattern(RecParams.getInstance.hpbw_deg * 2, a) ;
gXY = V * gg ; gYX = V * gg ;
    


%% complex (voltage) co- and x- patterns : X-PORT - v-pol
magg = sqrt(abs(gXX) .^2 + abs(gXY) .^2) ;
maxg = max(max(magg)) ;

% complex normalized (voltage) pattern
gnXX = gXX / maxg ;  
gnXY = gXY / maxg ;

%% complex (voltage) co- and x- patterns : Y-PORT - h-pol
magg = sqrt(abs(gYX) .^2 + abs(gYY) .^2) ;
maxg = max(max(magg)) ;

% complex normalized (voltage) pattern
gnYX = gYX / maxg ;  
gnYY = gYY / maxg ;

%% Antenna Pattern Matrix Elements

g11 = abs(gnXX) .^ 2 ;
g12 = abs(gnXY) .^ 2 ;
g13 = real(gnXX .* conj(gnXY)) ;
g14 = -imag(gnXX .* conj(gnXY)) ;

g21 = abs(gnYX) .^ 2 ;
g22 = abs(gnYY) .^ 2 ;
g23 = real(gnYX .* conj(gnYY)) ;
g24 = -imag(gnYX .* conj(gnYY)) ;

g31 = 2 * real(gnXX .* conj(gnYX)) ; 
g32 = 2 * real(gnXY .* conj(gnYY)) ; 
g33 = real(gnXX .* conj(gnYY) + gnXY .* conj(gnYX)) ;
g34 = -imag(gnXX .* conj(gnYY) - gnXY .* conj(gnYX)) ;

g41 = 2 * imag(gnXX .* conj(gnYX)) ; 
g42 = 2 * imag(gnXY .* conj(gnYY)) ; 
g43 = imag(gnXX .* conj(gnYY) + gnXY .* conj(gnYX)) ;
g44 = real(gnXX .* conj(gnYY) - gnXY .* conj(gnYX)) ;

%% Antenna Pattern Matrix

G = cell(4) ;

G{1,1} = g11 ; G{1,2} = g12 ; G{1,3} = g13 ; G{1,4} = g14 ;
G{2,1} = g21 ; G{2,2} = g22 ; G{2,3} = g23 ; G{2,4} = g24 ;
G{3,1} = g31 ; G{3,2} = g32 ; G{3,3} = g33 ; G{3,4} = g34 ;
G{4,1} = g41 ; G{4,2} = g42 ; G{4,3} = g43 ; G{4,4} = g44 ;

%%

g = cell(2) ;

g{1,1} = gnXX ; g{1,2} = gnXY ;
g{2,1} = gnYX ; g{2,2} = gnYY ; 

%% Half-Power Beanwidth

% X-port
Gn_co = G{1, 1} ;
Gn_x = G{1, 2} ;

Gn = Gn_co + Gn_x ; % co- + x- pols

indhpbw = (Gn >= 0.49) & (Gn <= 0.51) ;
hpbwX = mean(mean(th(indhpbw))) ;

del = 0 ;
while isnan(hpbwX)
    indhpbw = (Gn >= (0.50 - del)) & (Gn <= (0.50 + del)) ;
    hpbwX = mean(mean(th(indhpbw))) ;
    del = del + 0.01 ;
end

% Y-port
Gn_co = G{2, 2} ;
Gn_x = G{2, 1} ;

Gn = Gn_co + Gn_x ; % co- + x- pols

indhpbw = (Gn >= 0.49) & (Gn <= 0.51) ;
hpbwY = mean(mean(th(indhpbw))) ;

del = 0 ;
while isnan(hpbwY)
    indhpbw = (Gn >= (0.50 - del)) & (Gn <= (0.50 + del)) ;
    hpbwY = mean(mean(th(indhpbw))) ;
    del = del + 0.01 ;
end

hpbw2 = hpbwX + hpbwY ;  % Main beam

hpbw2 = hpbw2 * 180 / pi ;

%% Saving
save([SimulationFolders.getInstance.ant_lookup '\AntPat.mat'], 'G', 'g', 'th', 'ph')

       
end


function [th, ph, gg] = GGpattern(thsd, a)

% Beamwidth
% thsd = 12, 6, 3

% Sidelobe levels
% a = 0.35 (15 dB), 0.25 (20 dB), 0.12 (30 dB), 0.055 (40 db)

% TO-DO: Magic numbers?

Nth = 361 ;
Nph = 721 ;

th2 = linspace(0, pi, Nth) ;
ph2 = linspace(0, 2 * pi, Nph) ;

[th, ph] =  meshgrid(th2, ph2);

% Angle span (Beamwidth)
% thsd = 12 ;                     
ths = degtorad(thsd) ; 

% Generalized Gaussian Pattern parameters
alpha = 0.2 ; % 0.5 ;  % sidelobe width                 
% a = 0.35 ;  % sidelobe level

% Generelized Gaussian
gg = abs(1 / (1 - a) * exp( -(tan(th) / tan(ths)) .^ 2)...
        - a / (1 - a) * exp(-(alpha * tan(th) / tan(ths)) .^ 2)) ;

XX = min(min(gg(:, (th2 > 0.4*pi) & (th2 < 0.45*pi)))) ;
gg(:, th2 > pi/2) = XX ;
gg(gg < XX) = XX ;

end