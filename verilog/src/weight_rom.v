`timescale 1ns / 1ps

module weight_rom #(
    parameter DATA_W = 8
)(
    output wire [DATA_W*75-1:0]  l1_weights_flat,
    output wire [DATA_W*225-1:0] l2_weights_flat,
    output wire [DATA_W*480-1:0] fc_weights_flat 
);
    reg signed [DATA_W-1:0] l1_mem [0:74];
    reg signed [DATA_W-1:0] l2_mem [0:224];
    reg signed [DATA_W-1:0] fc_mem [0:479]; 

    initial begin
        // Layer 1 Weights
        l1_mem[0]=-14; l1_mem[1]=-116; l1_mem[2]=-127; l1_mem[3]=-94; l1_mem[4]=-4; l1_mem[5]=-94; l1_mem[6]=-81; l1_mem[7]=-81; l1_mem[8]=-6; l1_mem[9]=73; 
        l1_mem[10]=-82; l1_mem[11]=-108; l1_mem[12]=-38; l1_mem[13]=44; l1_mem[14]=98; l1_mem[15]=-76; l1_mem[16]=-71; l1_mem[17]=8; l1_mem[18]=64; l1_mem[19]=84; 
        l1_mem[20]=-79; l1_mem[21]=-72; l1_mem[22]=30; l1_mem[23]=70; l1_mem[24]=60; l1_mem[25]=25; l1_mem[26]=41; l1_mem[27]=93; l1_mem[28]=63; l1_mem[29]=47; 
        l1_mem[30]=59; l1_mem[31]=103; l1_mem[32]=80; l1_mem[33]=-1; l1_mem[34]=34; l1_mem[35]=-25; l1_mem[36]=-84; l1_mem[37]=-100; l1_mem[38]=-18; l1_mem[39]=69; 
        l1_mem[40]=-103; l1_mem[41]=-60; l1_mem[42]=-127; l1_mem[43]=-68; l1_mem[44]=-70; l1_mem[45]=1; l1_mem[46]=8; l1_mem[47]=46; l1_mem[48]=12; l1_mem[49]=-93; 
        l1_mem[50]=6; l1_mem[51]=75; l1_mem[52]=120; l1_mem[53]=89; l1_mem[54]=51; l1_mem[55]=29; l1_mem[56]=-19; l1_mem[57]=49; l1_mem[58]=36; l1_mem[59]=58; 
        l1_mem[60]=7; l1_mem[61]=-16; l1_mem[62]=-48; l1_mem[63]=44; l1_mem[64]=56; l1_mem[65]=-90; l1_mem[66]=-30; l1_mem[67]=8; l1_mem[68]=118; l1_mem[69]=47; 
        l1_mem[70]=-32; l1_mem[71]=22; l1_mem[72]=127; l1_mem[73]=87; l1_mem[74]=8; 

        // Layer 2 Weights (Input Channel Flipped)
        l2_mem[0]=-28; l2_mem[1]=1; l2_mem[2]=-17; l2_mem[3]=-55; l2_mem[4]=32; l2_mem[5]=40; l2_mem[6]=21; l2_mem[7]=4; l2_mem[8]=8; l2_mem[9]=86; 
        l2_mem[10]=61; l2_mem[11]=39; l2_mem[12]=77; l2_mem[13]=29; l2_mem[14]=63; l2_mem[15]=127; l2_mem[16]=102; l2_mem[17]=69; l2_mem[18]=43; l2_mem[19]=6; 
        l2_mem[20]=12; l2_mem[21]=49; l2_mem[22]=29; l2_mem[23]=71; l2_mem[24]=36; l2_mem[25]=-19; l2_mem[26]=-35; l2_mem[27]=59; l2_mem[28]=51; l2_mem[29]=-8; 
        l2_mem[30]=18; l2_mem[31]=15; l2_mem[32]=-35; l2_mem[33]=-60; l2_mem[34]=-84; l2_mem[35]=29; l2_mem[36]=-11; l2_mem[37]=-26; l2_mem[38]=-47; l2_mem[39]=-84; 
        l2_mem[40]=49; l2_mem[41]=-17; l2_mem[42]=-29; l2_mem[43]=-14; l2_mem[44]=-43; l2_mem[45]=21; l2_mem[46]=-25; l2_mem[47]=-48; l2_mem[48]=-10; l2_mem[49]=-65; 
        l2_mem[50]=22; l2_mem[51]=-35; l2_mem[52]=-49; l2_mem[53]=46; l2_mem[54]=117; l2_mem[55]=-33; l2_mem[56]=-51; l2_mem[57]=-41; l2_mem[58]=60; l2_mem[59]=70; 
        l2_mem[60]=-71; l2_mem[61]=-53; l2_mem[62]=40; l2_mem[63]=59; l2_mem[64]=38; l2_mem[65]=-12; l2_mem[66]=21; l2_mem[67]=26; l2_mem[68]=52; l2_mem[69]=-23; 
        l2_mem[70]=2; l2_mem[71]=18; l2_mem[72]=0; l2_mem[73]=13; l2_mem[74]=-21; l2_mem[75]=-60; l2_mem[76]=-60; l2_mem[77]=-71; l2_mem[78]=-15; l2_mem[79]=78; 
        l2_mem[80]=-31; l2_mem[81]=-78; l2_mem[82]=-6; l2_mem[83]=13; l2_mem[84]=-19; l2_mem[85]=-20; l2_mem[86]=3; l2_mem[87]=8; l2_mem[88]=-57; l2_mem[89]=-82; 
        l2_mem[90]=4; l2_mem[91]=21; l2_mem[92]=-48; l2_mem[93]=-10; l2_mem[94]=-44; l2_mem[95]=20; l2_mem[96]=11; l2_mem[97]=51; l2_mem[98]=42; l2_mem[99]=90; 
        l2_mem[100]=20; l2_mem[101]=22; l2_mem[102]=29; l2_mem[103]=-24; l2_mem[104]=-94; l2_mem[105]=59; l2_mem[106]=65; l2_mem[107]=2; l2_mem[108]=-2; l2_mem[109]=-75; 
        l2_mem[110]=45; l2_mem[111]=48; l2_mem[112]=-19; l2_mem[113]=1; l2_mem[114]=19; l2_mem[115]=4; l2_mem[116]=33; l2_mem[117]=42; l2_mem[118]=59; l2_mem[119]=17; 
        l2_mem[120]=0; l2_mem[121]=19; l2_mem[122]=29; l2_mem[123]=-31; l2_mem[124]=-49; l2_mem[125]=-127; l2_mem[126]=-55; l2_mem[127]=-37; l2_mem[128]=25; l2_mem[129]=42; 
        l2_mem[130]=-1; l2_mem[131]=0; l2_mem[132]=78; l2_mem[133]=37; l2_mem[134]=29; l2_mem[135]=105; l2_mem[136]=105; l2_mem[137]=94; l2_mem[138]=-28; l2_mem[139]=-24; 
        l2_mem[140]=122; l2_mem[141]=28; l2_mem[142]=-20; l2_mem[143]=-26; l2_mem[144]=-8; l2_mem[145]=75; l2_mem[146]=3; l2_mem[147]=-11; l2_mem[148]=-15; l2_mem[149]=-7; 
        l2_mem[150]=47; l2_mem[151]=64; l2_mem[152]=75; l2_mem[153]=-2; l2_mem[154]=-8; l2_mem[155]=32; l2_mem[156]=1; l2_mem[157]=-21; l2_mem[158]=-14; l2_mem[159]=-17; 
        l2_mem[160]=-7; l2_mem[161]=-63; l2_mem[162]=-67; l2_mem[163]=-79; l2_mem[164]=-2; l2_mem[165]=5; l2_mem[166]=-45; l2_mem[167]=-39; l2_mem[168]=-28; l2_mem[169]=34; 
        l2_mem[170]=30; l2_mem[171]=47; l2_mem[172]=27; l2_mem[173]=-21; l2_mem[174]=-21; l2_mem[175]=108; l2_mem[176]=120; l2_mem[177]=127; l2_mem[178]=83; l2_mem[179]=-18; 
        l2_mem[180]=73; l2_mem[181]=69; l2_mem[182]=23; l2_mem[183]=50; l2_mem[184]=-7; l2_mem[185]=18; l2_mem[186]=77; l2_mem[187]=58; l2_mem[188]=51; l2_mem[189]=-56; 
        l2_mem[190]=39; l2_mem[191]=89; l2_mem[192]=107; l2_mem[193]=39; l2_mem[194]=-18; l2_mem[195]=55; l2_mem[196]=115; l2_mem[197]=96; l2_mem[198]=66; l2_mem[199]=33; 
        l2_mem[200]=-37; l2_mem[201]=-31; l2_mem[202]=-23; l2_mem[203]=7; l2_mem[204]=45; l2_mem[205]=-39; l2_mem[206]=-23; l2_mem[207]=-20; l2_mem[208]=4; l2_mem[209]=62; 
        l2_mem[210]=-15; l2_mem[211]=-25; l2_mem[212]=18; l2_mem[213]=49; l2_mem[214]=58; l2_mem[215]=-1; l2_mem[216]=11; l2_mem[217]=-19; l2_mem[218]=-9; l2_mem[219]=26; 
        l2_mem[220]=17; l2_mem[221]=17; l2_mem[222]=4; l2_mem[223]=-24; l2_mem[224]=-58; 

        // FC Weights
        fc_mem[0]=-39; fc_mem[1]=2; fc_mem[2]=22; fc_mem[3]=-35; fc_mem[4]=44; fc_mem[5]=74; fc_mem[6]=-56; fc_mem[7]=47; fc_mem[8]=-81; fc_mem[9]=-16; 
        fc_mem[10]=53; fc_mem[11]=-127; fc_mem[12]=8; fc_mem[13]=-31; fc_mem[14]=25; fc_mem[15]=-7; fc_mem[16]=51; fc_mem[17]=23; fc_mem[18]=-89; fc_mem[19]=8; 
        fc_mem[20]=-14; fc_mem[21]=-24; fc_mem[22]=-81; fc_mem[23]=-113; fc_mem[24]=-61; fc_mem[25]=73; fc_mem[26]=54; fc_mem[27]=-16; fc_mem[28]=-5; fc_mem[29]=37; 
        fc_mem[30]=53; fc_mem[31]=-57; fc_mem[32]=90; fc_mem[33]=-31; fc_mem[34]=40; fc_mem[35]=-9; fc_mem[36]=-69; fc_mem[37]=98; fc_mem[38]=8; fc_mem[39]=41; 
        fc_mem[40]=7; fc_mem[41]=-19; fc_mem[42]=33; fc_mem[43]=8; fc_mem[44]=-9; fc_mem[45]=-39; fc_mem[46]=54; fc_mem[47]=18; fc_mem[48]=4; fc_mem[49]=56; 
        fc_mem[50]=-10; fc_mem[51]=-127; fc_mem[52]=-36; fc_mem[53]=17; fc_mem[54]=-70; fc_mem[55]=-55; fc_mem[56]=36; fc_mem[57]=20; fc_mem[58]=6; fc_mem[59]=99; 
        fc_mem[60]=22; fc_mem[61]=-71; fc_mem[62]=-66; fc_mem[63]=-84; fc_mem[64]=-12; fc_mem[65]=-40; fc_mem[66]=-33; fc_mem[67]=-31; fc_mem[68]=-4; fc_mem[69]=27; 
        fc_mem[70]=41; fc_mem[71]=42; fc_mem[72]=81; fc_mem[73]=-80; fc_mem[74]=22; fc_mem[75]=-71; fc_mem[76]=35; fc_mem[77]=104; fc_mem[78]=-63; fc_mem[79]=3; 
        fc_mem[80]=-29; fc_mem[81]=17; fc_mem[82]=-24; fc_mem[83]=54; fc_mem[84]=18; fc_mem[85]=-86; fc_mem[86]=24; fc_mem[87]=-73; fc_mem[88]=81; fc_mem[89]=35; 
        fc_mem[90]=-50; fc_mem[91]=9; fc_mem[92]=24; fc_mem[93]=88; fc_mem[94]=25; fc_mem[95]=-63; fc_mem[96]=39; fc_mem[97]=7; fc_mem[98]=18; fc_mem[99]=-5; 
        fc_mem[100]=8; fc_mem[101]=-127; fc_mem[102]=-18; fc_mem[103]=-28; fc_mem[104]=-55; fc_mem[105]=-16; fc_mem[106]=-89; fc_mem[107]=-71; fc_mem[108]=41; fc_mem[109]=-21; 
        fc_mem[110]=27; fc_mem[111]=-51; fc_mem[112]=-44; fc_mem[113]=-46; fc_mem[114]=-62; fc_mem[115]=-21; fc_mem[116]=-40; fc_mem[117]=-29; fc_mem[118]=-73; fc_mem[119]=-7; 
        fc_mem[120]=73; fc_mem[121]=28; fc_mem[122]=-23; fc_mem[123]=21; fc_mem[124]=54; fc_mem[125]=-7; fc_mem[126]=1; fc_mem[127]=13; fc_mem[128]=-5; fc_mem[129]=53; 
        fc_mem[130]=91; fc_mem[131]=33; fc_mem[132]=-43; fc_mem[133]=43; fc_mem[134]=82; fc_mem[135]=1; fc_mem[136]=48; fc_mem[137]=63; fc_mem[138]=41; fc_mem[139]=20; 
        fc_mem[140]=47; fc_mem[141]=67; fc_mem[142]=41; fc_mem[143]=-96; fc_mem[144]=83; fc_mem[145]=-3; fc_mem[146]=-50; fc_mem[147]=18; fc_mem[148]=20; fc_mem[149]=-127; 
        fc_mem[150]=7; fc_mem[151]=-21; fc_mem[152]=8; fc_mem[153]=32; fc_mem[154]=-21; fc_mem[155]=-13; fc_mem[156]=-10; fc_mem[157]=-56; fc_mem[158]=28; fc_mem[159]=-27; 
        fc_mem[160]=18; fc_mem[161]=-14; fc_mem[162]=16; fc_mem[163]=53; fc_mem[164]=6; fc_mem[165]=-8; fc_mem[166]=32; fc_mem[167]=37; fc_mem[168]=29; fc_mem[169]=-37; 
        fc_mem[170]=14; fc_mem[171]=1; fc_mem[172]=14; fc_mem[173]=-33; fc_mem[174]=0; fc_mem[175]=-13; fc_mem[176]=-18; fc_mem[177]=-3; fc_mem[178]=-15; fc_mem[179]=-45; 
        fc_mem[180]=55; fc_mem[181]=-42; fc_mem[182]=-58; fc_mem[183]=64; fc_mem[184]=-16; fc_mem[185]=-66; fc_mem[186]=-9; fc_mem[187]=-15; fc_mem[188]=-35; fc_mem[189]=-21; 
        fc_mem[190]=19; fc_mem[191]=4; fc_mem[192]=-120; fc_mem[193]=-5; fc_mem[194]=45; fc_mem[195]=-72; fc_mem[196]=-104; fc_mem[197]=26; fc_mem[198]=-127; fc_mem[199]=-126; 
        fc_mem[200]=20; fc_mem[201]=8; fc_mem[202]=21; fc_mem[203]=63; fc_mem[204]=25; fc_mem[205]=121; fc_mem[206]=30; fc_mem[207]=43; fc_mem[208]=23; fc_mem[209]=45; 
        fc_mem[210]=-6; fc_mem[211]=35; fc_mem[212]=6; fc_mem[213]=3; fc_mem[214]=28; fc_mem[215]=75; fc_mem[216]=13; fc_mem[217]=127; fc_mem[218]=-34; fc_mem[219]=-22; 
        fc_mem[220]=-6; fc_mem[221]=-11; fc_mem[222]=36; fc_mem[223]=45; fc_mem[224]=-101; fc_mem[225]=-52; fc_mem[226]=73; fc_mem[227]=7; fc_mem[228]=-68; fc_mem[229]=-89; 
        fc_mem[230]=-23; fc_mem[231]=-33; fc_mem[232]=-55; fc_mem[233]=38; fc_mem[234]=-73; fc_mem[235]=57; fc_mem[236]=-32; fc_mem[237]=2; fc_mem[238]=-9; fc_mem[239]=13; 
        fc_mem[240]=-49; fc_mem[241]=7; fc_mem[242]=58; fc_mem[243]=45; fc_mem[244]=6; fc_mem[245]=86; fc_mem[246]=88; fc_mem[247]=22; fc_mem[248]=22; fc_mem[249]=12; 
        fc_mem[250]=90; fc_mem[251]=4; fc_mem[252]=-12; fc_mem[253]=-17; fc_mem[254]=7; fc_mem[255]=4; fc_mem[256]=-11; fc_mem[257]=-31; fc_mem[258]=39; fc_mem[259]=-11; 
        fc_mem[260]=29; fc_mem[261]=46; fc_mem[262]=-14; fc_mem[263]=-60; fc_mem[264]=48; fc_mem[265]=9; fc_mem[266]=-58; fc_mem[267]=-15; fc_mem[268]=-36; fc_mem[269]=-27; 
        fc_mem[270]=-13; fc_mem[271]=-81; fc_mem[272]=-58; fc_mem[273]=-3; fc_mem[274]=-127; fc_mem[275]=-93; fc_mem[276]=65; fc_mem[277]=20; fc_mem[278]=-41; fc_mem[279]=-22; 
        fc_mem[280]=10; fc_mem[281]=-43; fc_mem[282]=14; fc_mem[283]=7; fc_mem[284]=8; fc_mem[285]=11; fc_mem[286]=-35; fc_mem[287]=-2; fc_mem[288]=-103; fc_mem[289]=-67; 
        fc_mem[290]=52; fc_mem[291]=-53; fc_mem[292]=-41; fc_mem[293]=91; fc_mem[294]=-25; fc_mem[295]=19; fc_mem[296]=50; fc_mem[297]=-52; fc_mem[298]=73; fc_mem[299]=63; 
        fc_mem[300]=-28; fc_mem[301]=-32; fc_mem[302]=13; fc_mem[303]=45; fc_mem[304]=-1; fc_mem[305]=38; fc_mem[306]=4; fc_mem[307]=35; fc_mem[308]=-29; fc_mem[309]=60; 
        fc_mem[310]=51; fc_mem[311]=-93; fc_mem[312]=-99; fc_mem[313]=22; fc_mem[314]=14; fc_mem[315]=8; fc_mem[316]=18; fc_mem[317]=57; fc_mem[318]=62; fc_mem[319]=-44; 
        fc_mem[320]=-13; fc_mem[321]=68; fc_mem[322]=-3; fc_mem[323]=-58; fc_mem[324]=-127; fc_mem[325]=44; fc_mem[326]=-30; fc_mem[327]=-28; fc_mem[328]=69; fc_mem[329]=-39; 
        fc_mem[330]=33; fc_mem[331]=27; fc_mem[332]=-38; fc_mem[333]=-80; fc_mem[334]=-33; fc_mem[335]=-4; fc_mem[336]=73; fc_mem[337]=41; fc_mem[338]=-116; fc_mem[339]=7; 
        fc_mem[340]=-2; fc_mem[341]=-127; fc_mem[342]=-19; fc_mem[343]=-19; fc_mem[344]=-7; fc_mem[345]=10; fc_mem[346]=-7; fc_mem[347]=-32; fc_mem[348]=82; fc_mem[349]=-121; 
        fc_mem[350]=-35; fc_mem[351]=11; fc_mem[352]=-42; fc_mem[353]=29; fc_mem[354]=23; fc_mem[355]=23; fc_mem[356]=-9; fc_mem[357]=53; fc_mem[358]=-40; fc_mem[359]=44; 
        fc_mem[360]=4; fc_mem[361]=-38; fc_mem[362]=60; fc_mem[363]=-83; fc_mem[364]=-35; fc_mem[365]=2; fc_mem[366]=-10; fc_mem[367]=43; fc_mem[368]=-51; fc_mem[369]=0; 
        fc_mem[370]=33; fc_mem[371]=8; fc_mem[372]=31; fc_mem[373]=-88; fc_mem[374]=-3; fc_mem[375]=-53; fc_mem[376]=-58; fc_mem[377]=69; fc_mem[378]=1; fc_mem[379]=-3; 
        fc_mem[380]=32; fc_mem[381]=2; fc_mem[382]=13; fc_mem[383]=48; fc_mem[384]=-33; fc_mem[385]=29; fc_mem[386]=46; fc_mem[387]=68; fc_mem[388]=-8; fc_mem[389]=53; 
        fc_mem[390]=33; fc_mem[391]=35; fc_mem[392]=0; fc_mem[393]=27; fc_mem[394]=-17; fc_mem[395]=-45; fc_mem[396]=-24; fc_mem[397]=54; fc_mem[398]=-58; fc_mem[399]=-46; 
        fc_mem[400]=-3; fc_mem[401]=-103; fc_mem[402]=27; fc_mem[403]=-2; fc_mem[404]=-23; fc_mem[405]=-3; fc_mem[406]=34; fc_mem[407]=6; fc_mem[408]=12; fc_mem[409]=-64; 
        fc_mem[410]=-39; fc_mem[411]=-2; fc_mem[412]=11; fc_mem[413]=23; fc_mem[414]=-22; fc_mem[415]=2; fc_mem[416]=15; fc_mem[417]=24; fc_mem[418]=49; fc_mem[419]=-43; 
        fc_mem[420]=-100; fc_mem[421]=113; fc_mem[422]=43; fc_mem[423]=-9; fc_mem[424]=28; fc_mem[425]=-30; fc_mem[426]=79; fc_mem[427]=-58; fc_mem[428]=-38; fc_mem[429]=11; 
        fc_mem[430]=-127; fc_mem[431]=-45; fc_mem[432]=-14; fc_mem[433]=-21; fc_mem[434]=9; fc_mem[435]=63; fc_mem[436]=58; fc_mem[437]=-11; fc_mem[438]=26; fc_mem[439]=50; 
        fc_mem[440]=-89; fc_mem[441]=29; fc_mem[442]=-18; fc_mem[443]=-72; fc_mem[444]=-35; fc_mem[445]=91; fc_mem[446]=104; fc_mem[447]=42; fc_mem[448]=5; fc_mem[449]=61; 
        fc_mem[450]=-56; fc_mem[451]=-9; fc_mem[452]=38; fc_mem[453]=38; fc_mem[454]=-63; fc_mem[455]=-11; fc_mem[456]=-7; fc_mem[457]=49; fc_mem[458]=-78; fc_mem[459]=43; 
        fc_mem[460]=5; fc_mem[461]=-94; fc_mem[462]=5; fc_mem[463]=0; fc_mem[464]=-17; fc_mem[465]=-127; fc_mem[466]=-22; fc_mem[467]=18; fc_mem[468]=31; fc_mem[469]=-66; 
        fc_mem[470]=-22; fc_mem[471]=9; fc_mem[472]=-35; fc_mem[473]=-26; fc_mem[474]=-116; fc_mem[475]=-10; fc_mem[476]=-50; fc_mem[477]=-72; fc_mem[478]=25; fc_mem[479]=24; 
    end

    genvar i;
    generate
        for (i=0; i<75; i=i+1) begin : L1_MAP
            assign l1_weights_flat[8*i +: 8] = l1_mem[i]; 
        end
        for (i=0; i<225; i=i+1) begin : L2_MAP
            assign l2_weights_flat[8*i +: 8] = l2_mem[i];
        end
        for (i=0; i<480; i=i+1) begin : FC_MAP
            assign fc_weights_flat[8*i +: 8] = fc_mem[i];
        end
    endgenerate
endmodule
