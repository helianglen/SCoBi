%% Mehmet Kurum
% Feb 25, 2017 

function bistaticGeometry(rd, th0t, ph0t, th0r, ph0r, Bthrd)

%% Antenna Parameters/Orientation - Receiver
% 3dB Beamwidths
% Bthrd = 40 ;
Bthr = degtorad(Bthrd) ;
% Bphrd = 40 ;
Bphr = degtorad(Bthrd) ;


%% Antenna Rotation Matrix for reciever

% Rotation about z-axis (Azimuth rotation)
AntRotZr = [cos(ph0r) -sin(ph0r) 0;
    sin(ph0r) cos(ph0r)   0    ;
    0 0 1] ;

% Rotation about y-axis (Elevation rotation)
AntRotYr = [-cos(th0r) 0  sin(th0r);
    0       1     0    ;
    -sin(th0r) 0 -cos(th0r)] ;

% Rotation in both azimuth and elevation
AntRotr = AntRotZr  * AntRotYr ;

%% Azimuth direction of transmitted signal.

AntRotZt = [cos(ph0t) -sin(ph0t) 0;
    sin(ph0t) cos(ph0t)   0    ;
    0 0 1] ;

%% Transmitter position

% T : Transmitter Antenna position
pT = rd * [sin(th0t) * cos(ph0t); sin(th0t) * sin(ph0t); cos(th0t)] ;
ht = pT(3) ;
% TI : Transmitter Image Antenna position
pTI = [pT(1); pT(2); -ht] ;

% A : Antenna projection point on the ground
% % pHt = [pT(1), pT(2), 0] ;

%% Specular point and 1st Fresnel zone ellipse
[S0x, x1, ax1, by1] = calcFresnelZones(ht, RecParams.getInstance.hr) ;

pS = [S0x; 0; 0] ;
pS2 = AntRotZt * pS  ; % specular point location

% Center of first Fresnel ellipse
pSc = [x1(1); 0; 0] ;
pSc2 = AntRotZt * pSc  ;

ellipse_s = [ax1, by1] ; % specular point Fresnel zone
ellipse_s_centers = AntRotZt * [x1'; zeros(1,10); zeros(1,10)] ;

%% Reciever footprint - ellipse

% major axis
dar = RecParams.getInstance.hr * (tan(th0r + Bthr / 2) - tan(th0r - Bthr / 2)) ;

% angle of incidnce at the center of the ellipse
thcr = atan(tan(th0r + Bthr / 2) - dar / RecParams.getInstance.hr / 2) ;
thcrd = radtodeg(thcr) ; %#ok<NASGU>

% minor axis
dbr = 2 * RecParams.getInstance.hr * sec(thcr) * tan(Bphr / 2) ;

ellipse_r = [dar; dbr] ; % receiver footprint

%% Receiver position and pointing locations

% R : Receiver Antenna position
pR = [0; 0; RecParams.getInstance.hr] ;
% pR2 = AntRotZr * pR ;

% RI : Image Receiver Antenna position
pRI = [0; 0; - RecParams.getInstance.hr] ;

% G : Antenna projection point on the ground
% Center of reference coordinate system
pG = [0; 0; 0] ;
pG2 = AntRotZr * pG ;

% B : Boresight point
pBr = [RecParams.getInstance.hr * tan(th0r); 0; 0] ;
pBr2 = AntRotZr * pBr ;

% Ellipse Center - C
pCr = [RecParams.getInstance.hr * tan(thcr); 0; 0] ;
pCr2 = AntRotZr * pCr ;

%% all points
% pT: Transmitter, pS2: specular point, pR2: receiver, pG2: ground (reference), pBr2:boresight,
% pCr2: center of footprint, pSc2: center of fresnel zone
AllPoints = [pT, pTI, pS2, pR, pRI, pG2, pBr2, pCr2, pSc2] ;

%% Satellite to Receiver
RT = pR - pT ;
magRT = vectorMagnitude(RT) ;
idn = RT / magRT ;  % propagation vector (i_d^-)

%% Satellite to Specular point
ST = pS2 - pT ;
magST = vectorMagnitude(ST) ;
isn = ST / magST ;  % propagation vector (i_s^-)

%% Specular point to Reciever
RS = pR - pS2 ;
magRS = vectorMagnitude(RS) ;
osp = RS / magRS ;  % propagation vector (o_s^+)

%% Specular point to Reciever
RIS = pRI - pS2 ;
magRIS = vectorMagnitude(RIS) ;
osn = RIS / magRIS ;  % propagation vector (o_s^-)

%% Ground Reference Coordinate System (East-North-Up)
% located on the ground where the receiver is projected
ux = [1 0 0] ;
uy = [0 1 0] ;
uz = [0 0 1] ;

%% Receiver Antenna Coordinate System
uxr = (AntRotr * ux')' ;
uyr = (AntRotr * uy')' ;
uzr = (AntRotr * uz')' ;

%% Image of Receiver Antenna Coordinate System
uxrI = [uxr(1), uxr(2), -uxr(3)] ;
uyrI = [uyr(1), uyr(2), -uyr(3)] ;
uzrI = [uzr(1), uzr(2), -uzr(3)] ;

%% Specular Point Coordinate System
uxs = (AntRotZt * ux')' ; 
uys = (AntRotZt * uy')' ;
uzs = (AntRotZt * uz')' ;

%% Transformations

% Transformation matrix for transforming a vector from the ground frame
% to local (specular) ground system
Tgs = [uxs ; uys ; uzs] ; % G -> S

% Transformation matrix for transforming a vector from the ground frame
% to receiver system
Tgr = [uxr ; uyr ; uzr] ; % G -> R

% Transformation matrix for transforming a vector from the ground frame
% to Image receiver system
TgrI = [uxrI ; uyrI ; uzrI] ; % G -> RI

% % Receive antenna Coordinates in local (specular) ground system
% Trs = Tgs * Tgr .' ;   % R -> S

%% The incidence angle on the receiver in receiver coordinates

% propagation vector from satellite to reciever in receiver antenna system
idn_rf = Tgr * idn ;

% FROM SAT TO REC
% off-axis angle of zr towards satellite
th0 = acos(-idn_rf(3)) * 180 / pi ;
%  orientation - azimuth
ph0 = atan2(-idn_rf(2), -idn_rf(1)) * 180 / pi ;

AngT2R_rf = [th0; convertAngleTo360Range( ph0 )]  ;

% propagation vector from specular point to receiver in receiver antenna system
osp_rf = Tgr * osp ;

% FROM SPEC TO REC
% off-axis angle of zr towards specular point
th0 = acos(-osp_rf(3)) * 180 / pi ;
%  orientation - azimuth
ph0 = atan2(-osp_rf(2), -osp_rf(1)) * 180 / pi ;

AngS2R_rf = [th0; convertAngleTo360Range( ph0 ) ]  ;


%% The incidence angle in spacular frame

% propagation vector from satellite to ground in local (specular) ground system
isn_sf = Tgs * isn ;

% FROM SAT TO SPEC
% off-axis angle of zs towards satellite
th0 = acos(-isn_sf(3)) * 180 / pi ;
%  orientation - azimuth
ph0 = atan2(-isn_sf(2), -isn_sf(1)) * 180 / pi ;

AngT2S_sf = [th0; convertAngleTo360Range( ph0 ) ]  ;


%% Saving. . . 

% AntRotZr - Receiver Rotation about z-axis (Azimuth rotation)
% AntRotYr - Receiver Rotation about y-axis (Elevation rotation)
% AntRotr  - Receiver Rotation in both azimuth and elevation
% AntRotZt -  Rotation matrix that describes azimuth direction of transmitted signal.
% ellipse_s - specular point Fresnel zone [major and minor axes]
% ellipse_r - receiver footprint ellipse [major and minor axes]
% AllPoints - pT, pS2, pR, pG2, pBr2, pCr2, pSc2 in ground (refrence) frame (G)
% AngT2R_rf - Incidence angle (T -> R) in receiver frame (R)
% AngS2R_rf - Incidence angle (S -> R) in receiver frame (R)
% AngT2S_sf - Incidence angle (T -> S) in specular frame (S)
% Tgs - Transformation G -> S
% Tgr - Transformation G -> R
% TgrI - Transformation G -> RI
% idn -  propagation vector (i_d^-)
% isn - propagation vector (i_s^-)
% osp - propagation vector (o_s^+)
% osn - propagation vector (o_s^-)

pathname = SimulationFolders.getInstance.config;
filename = 'idn' ;
writeVar(pathname, filename, idn) ;

filename = 'isn' ;
writeVar(pathname, filename, isn) ;

filename = 'osp' ;
writeVar(pathname, filename, osp) ;

filename = 'osn' ;
writeVar(pathname, filename, osn) ;

filename = 'Tgs' ;
writeVar(pathname, filename, Tgs) ;

filename = 'Tgr' ;
writeVar(pathname, filename, Tgr) ;

filename = 'TgrI' ;
writeVar(pathname, filename, TgrI) ;

filename = 'AntRotZr' ;
writeVar(pathname, filename, AntRotZr) ;

filename = 'AntRotYr' ;
writeVar(pathname, filename, AntRotYr) ;

filename = 'AntRotr' ;
writeVar(pathname, filename, AntRotr) ;

filename = 'AntRotZt' ;
writeVar(pathname, filename, AntRotZt) ;

filename = 'ellipse_s' ;
writeVar(pathname, filename, ellipse_s) ;

filename = 'ellipse_s_centers' ;
writeVar(pathname, filename, ellipse_s_centers) ;

filename = 'ellipse_r' ;
writeVar(pathname, filename, ellipse_r) ;

filename = 'AllPoints' ;
writeVar(pathname, filename, AllPoints) ;

filename = 'AngT2R_rf' ;
writeVar(pathname, filename, AngT2R_rf) ;

filename = 'AngS2R_rf' ;
writeVar(pathname, filename, AngS2R_rf) ;

filename = 'AngT2S_sf' ;
writeVar(pathname, filename, AngT2S_sf) ;


    
end
