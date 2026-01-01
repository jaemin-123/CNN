`timescale 1ns / 1ps

module weight_rom #(
    parameter DATA_W = 8
)(
    output reg [DATA_W*75-1:0]  l1_weights_flat,
    output reg [DATA_W*225-1:0] l2_weights_flat,
    output reg [DATA_W*480-1:0] fc_weights_flat 
);
    reg signed [DATA_W-1:0] l1_mem [0:74];
    reg signed [DATA_W-1:0] l2_mem [0:224];
    reg signed [DATA_W-1:0] fc_mem [0:479]; 
    integer i;

    initial begin
        // Layer 1 Weights (OutCh Flip + Kernel Flip)
        l1_mem[0]=16;         l1_mem[1]=31;         l1_mem[2]=4;         l1_mem[3]=-52;         l1_mem[4]=-109;         l1_mem[5]=33;         l1_mem[6]=51;         l1_mem[7]=43;         l1_mem[8]=-37;         l1_mem[9]=-127; 
        l1_mem[10]=63;         l1_mem[11]=6;         l1_mem[12]=-21;         l1_mem[13]=-97;         l1_mem[14]=-96;         l1_mem[15]=-33;         l1_mem[16]=-36;         l1_mem[17]=-73;         l1_mem[18]=-111;         l1_mem[19]=-16; 
        l1_mem[20]=-109;         l1_mem[21]=-98;         l1_mem[22]=-89;         l1_mem[23]=-27;         l1_mem[24]=-8;         l1_mem[25]=-27;         l1_mem[26]=-19;         l1_mem[27]=39;         l1_mem[28]=60;         l1_mem[29]=33; 
        l1_mem[30]=18;         l1_mem[31]=18;         l1_mem[32]=75;         l1_mem[33]=51;         l1_mem[34]=45;         l1_mem[35]=52;         l1_mem[36]=30;         l1_mem[37]=59;         l1_mem[38]=36;         l1_mem[39]=-15; 
        l1_mem[40]=102;         l1_mem[41]=37;         l1_mem[42]=7;         l1_mem[43]=19;         l1_mem[44]=-1;         l1_mem[45]=83;         l1_mem[46]=5;         l1_mem[47]=-8;         l1_mem[48]=17;         l1_mem[49]=3; 
        l1_mem[50]=1;         l1_mem[51]=6;         l1_mem[52]=18;         l1_mem[53]=13;         l1_mem[54]=35;         l1_mem[55]=33;         l1_mem[56]=25;         l1_mem[57]=55;         l1_mem[58]=86;         l1_mem[59]=61; 
        l1_mem[60]=54;         l1_mem[61]=60;         l1_mem[62]=36;         l1_mem[63]=24;         l1_mem[64]=73;         l1_mem[65]=-76;         l1_mem[66]=-46;         l1_mem[67]=-56;         l1_mem[68]=-85;         l1_mem[69]=-63; 
        l1_mem[70]=-53;         l1_mem[71]=-36;         l1_mem[72]=-62;         l1_mem[73]=-64;         l1_mem[74]=-45; 
        // Layer 2 Weights (All Dimensions Flip)
        l2_mem[0]=15;         l2_mem[1]=-59;         l2_mem[2]=-61;         l2_mem[3]=-36;         l2_mem[4]=-50;         l2_mem[5]=3;         l2_mem[6]=-2;         l2_mem[7]=-35;         l2_mem[8]=-44;         l2_mem[9]=-40; 
        l2_mem[10]=-10;         l2_mem[11]=-16;         l2_mem[12]=9;         l2_mem[13]=55;         l2_mem[14]=73;         l2_mem[15]=-71;         l2_mem[16]=-29;         l2_mem[17]=6;         l2_mem[18]=80;         l2_mem[19]=65; 
        l2_mem[20]=-38;         l2_mem[21]=-6;         l2_mem[22]=46;         l2_mem[23]=49;         l2_mem[24]=23;         l2_mem[25]=-26;         l2_mem[26]=-23;         l2_mem[27]=-18;         l2_mem[28]=-14;         l2_mem[29]=13; 
        l2_mem[30]=2;         l2_mem[31]=76;         l2_mem[32]=49;         l2_mem[33]=27;         l2_mem[34]=29;         l2_mem[35]=64;         l2_mem[36]=50;         l2_mem[37]=28;         l2_mem[38]=4;         l2_mem[39]=57; 
        l2_mem[40]=23;         l2_mem[41]=-53;         l2_mem[42]=-26;         l2_mem[43]=-11;         l2_mem[44]=55;         l2_mem[45]=-30;         l2_mem[46]=-36;         l2_mem[47]=-55;         l2_mem[48]=20;         l2_mem[49]=14; 
        l2_mem[50]=20;         l2_mem[51]=56;         l2_mem[52]=51;         l2_mem[53]=51;         l2_mem[54]=-24;         l2_mem[55]=2;         l2_mem[56]=50;         l2_mem[57]=72;         l2_mem[58]=55;         l2_mem[59]=-50; 
        l2_mem[60]=42;         l2_mem[61]=52;         l2_mem[62]=-7;         l2_mem[63]=-41;         l2_mem[64]=-76;         l2_mem[65]=-11;         l2_mem[66]=6;         l2_mem[67]=-71;         l2_mem[68]=-25;         l2_mem[69]=-11; 
        l2_mem[70]=6;         l2_mem[71]=33;         l2_mem[72]=-45;         l2_mem[73]=14;         l2_mem[74]=-30;         l2_mem[75]=50;         l2_mem[76]=9;         l2_mem[77]=-8;         l2_mem[78]=59;         l2_mem[79]=87; 
        l2_mem[80]=-48;         l2_mem[81]=-58;         l2_mem[82]=-125;         l2_mem[83]=-29;         l2_mem[84]=37;         l2_mem[85]=-59;         l2_mem[86]=-118;         l2_mem[87]=-111;         l2_mem[88]=-70;         l2_mem[89]=-13; 
        l2_mem[90]=-32;         l2_mem[91]=16;         l2_mem[92]=-64;         l2_mem[93]=-60;         l2_mem[94]=-40;         l2_mem[95]=34;         l2_mem[96]=55;         l2_mem[97]=40;         l2_mem[98]=36;         l2_mem[99]=46; 
        l2_mem[100]=34;         l2_mem[101]=-29;         l2_mem[102]=-48;         l2_mem[103]=-50;         l2_mem[104]=-8;         l2_mem[105]=84;         l2_mem[106]=26;         l2_mem[107]=-11;         l2_mem[108]=-2;         l2_mem[109]=2; 
        l2_mem[110]=10;         l2_mem[111]=6;         l2_mem[112]=-8;         l2_mem[113]=1;         l2_mem[114]=2;         l2_mem[115]=-30;         l2_mem[116]=-29;         l2_mem[117]=-63;         l2_mem[118]=-20;         l2_mem[119]=16; 
        l2_mem[120]=30;         l2_mem[121]=13;         l2_mem[122]=-31;         l2_mem[123]=10;         l2_mem[124]=-3;         l2_mem[125]=62;         l2_mem[126]=11;         l2_mem[127]=-26;         l2_mem[128]=10;         l2_mem[129]=60; 
        l2_mem[130]=86;         l2_mem[131]=50;         l2_mem[132]=10;         l2_mem[133]=34;         l2_mem[134]=31;         l2_mem[135]=19;         l2_mem[136]=59;         l2_mem[137]=72;         l2_mem[138]=46;         l2_mem[139]=60; 
        l2_mem[140]=5;         l2_mem[141]=68;         l2_mem[142]=76;         l2_mem[143]=39;         l2_mem[144]=87;         l2_mem[145]=-29;         l2_mem[146]=25;         l2_mem[147]=30;         l2_mem[148]=16;         l2_mem[149]=45; 
        l2_mem[150]=70;         l2_mem[151]=22;         l2_mem[152]=27;         l2_mem[153]=24;         l2_mem[154]=-45;         l2_mem[155]=127;         l2_mem[156]=62;         l2_mem[157]=97;         l2_mem[158]=73;         l2_mem[159]=-42; 
        l2_mem[160]=92;         l2_mem[161]=63;         l2_mem[162]=83;         l2_mem[163]=50;         l2_mem[164]=16;         l2_mem[165]=-4;         l2_mem[166]=89;         l2_mem[167]=47;         l2_mem[168]=28;         l2_mem[169]=27; 
        l2_mem[170]=-33;         l2_mem[171]=7;         l2_mem[172]=-24;         l2_mem[173]=-19;         l2_mem[174]=-30;         l2_mem[175]=6;         l2_mem[176]=-10;         l2_mem[177]=8;         l2_mem[178]=3;         l2_mem[179]=7; 
        l2_mem[180]=32;         l2_mem[181]=-4;         l2_mem[182]=-32;         l2_mem[183]=-53;         l2_mem[184]=31;         l2_mem[185]=-38;         l2_mem[186]=-82;         l2_mem[187]=-78;         l2_mem[188]=-81;         l2_mem[189]=-59; 
        l2_mem[190]=-63;         l2_mem[191]=-79;         l2_mem[192]=-53;         l2_mem[193]=-78;         l2_mem[194]=-85;         l2_mem[195]=30;         l2_mem[196]=76;         l2_mem[197]=69;         l2_mem[198]=-2;         l2_mem[199]=-15; 
        l2_mem[200]=-25;         l2_mem[201]=-22;         l2_mem[202]=14;         l2_mem[203]=21;         l2_mem[204]=25;         l2_mem[205]=20;         l2_mem[206]=15;         l2_mem[207]=-9;         l2_mem[208]=33;         l2_mem[209]=81; 
        l2_mem[210]=77;         l2_mem[211]=58;         l2_mem[212]=70;         l2_mem[213]=83;         l2_mem[214]=96;         l2_mem[215]=28;         l2_mem[216]=107;         l2_mem[217]=82;         l2_mem[218]=8;         l2_mem[219]=35; 
        l2_mem[220]=26;         l2_mem[221]=31;         l2_mem[222]=64;         l2_mem[223]=22;         l2_mem[224]=5; 
        // FC Weights (Permuted)
        fc_mem[0]=20;         fc_mem[1]=-24;         fc_mem[2]=22;         fc_mem[3]=-10;         fc_mem[4]=-33;         fc_mem[5]=0;         fc_mem[6]=-23;         fc_mem[7]=22;         fc_mem[8]=-10;         fc_mem[9]=23; 
        fc_mem[10]=45;         fc_mem[11]=9;         fc_mem[12]=22;         fc_mem[13]=-11;         fc_mem[14]=11;         fc_mem[15]=-31;         fc_mem[16]=-11;         fc_mem[17]=-53;         fc_mem[18]=42;         fc_mem[19]=-18; 
        fc_mem[20]=-64;         fc_mem[21]=-52;         fc_mem[22]=25;         fc_mem[23]=-7;         fc_mem[24]=-119;         fc_mem[25]=0;         fc_mem[26]=-10;         fc_mem[27]=-2;         fc_mem[28]=-5;         fc_mem[29]=51; 
        fc_mem[30]=21;         fc_mem[31]=12;         fc_mem[32]=31;         fc_mem[33]=-62;         fc_mem[34]=-47;         fc_mem[35]=-14;         fc_mem[36]=-83;         fc_mem[37]=-26;         fc_mem[38]=-19;         fc_mem[39]=-13; 
        fc_mem[40]=-12;         fc_mem[41]=36;         fc_mem[42]=71;         fc_mem[43]=15;         fc_mem[44]=42;         fc_mem[45]=27;         fc_mem[46]=23;         fc_mem[47]=-28;         fc_mem[48]=-25;         fc_mem[49]=65; 
        fc_mem[50]=-5;         fc_mem[51]=-5;         fc_mem[52]=-39;         fc_mem[53]=54;         fc_mem[54]=8;         fc_mem[55]=-89;         fc_mem[56]=-24;         fc_mem[57]=22;         fc_mem[58]=-85;         fc_mem[59]=70; 
        fc_mem[60]=63;         fc_mem[61]=-72;         fc_mem[62]=20;         fc_mem[63]=7;         fc_mem[64]=-9;         fc_mem[65]=-65;         fc_mem[66]=-101;         fc_mem[67]=-30;         fc_mem[68]=-38;         fc_mem[69]=-5; 
        fc_mem[70]=-127;         fc_mem[71]=44;         fc_mem[72]=35;         fc_mem[73]=-5;         fc_mem[74]=2;         fc_mem[75]=-36;         fc_mem[76]=17;         fc_mem[77]=-18;         fc_mem[78]=-25;         fc_mem[79]=-29; 
        fc_mem[80]=-41;         fc_mem[81]=61;         fc_mem[82]=-61;         fc_mem[83]=107;         fc_mem[84]=41;         fc_mem[85]=21;         fc_mem[86]=99;         fc_mem[87]=-15;         fc_mem[88]=-13;         fc_mem[89]=-116; 
        fc_mem[90]=9;         fc_mem[91]=-42;         fc_mem[92]=0;         fc_mem[93]=27;         fc_mem[94]=22;         fc_mem[95]=77;         fc_mem[96]=2;         fc_mem[97]=-3;         fc_mem[98]=4;         fc_mem[99]=-56; 
        fc_mem[100]=-3;         fc_mem[101]=-22;         fc_mem[102]=-21;         fc_mem[103]=1;         fc_mem[104]=-59;         fc_mem[105]=-6;         fc_mem[106]=9;         fc_mem[107]=-49;         fc_mem[108]=50;         fc_mem[109]=1; 
        fc_mem[110]=45;         fc_mem[111]=30;         fc_mem[112]=27;         fc_mem[113]=-59;         fc_mem[114]=6;         fc_mem[115]=24;         fc_mem[116]=-27;         fc_mem[117]=-80;         fc_mem[118]=1;         fc_mem[119]=-38; 
        fc_mem[120]=48;         fc_mem[121]=2;         fc_mem[122]=58;         fc_mem[123]=8;         fc_mem[124]=18;         fc_mem[125]=7;         fc_mem[126]=-9;         fc_mem[127]=32;         fc_mem[128]=32;         fc_mem[129]=-35; 
        fc_mem[130]=6;         fc_mem[131]=19;         fc_mem[132]=-76;         fc_mem[133]=-31;         fc_mem[134]=11;         fc_mem[135]=-16;         fc_mem[136]=-52;         fc_mem[137]=1;         fc_mem[138]=0;         fc_mem[139]=6; 
        fc_mem[140]=-3;         fc_mem[141]=59;         fc_mem[142]=77;         fc_mem[143]=38;         fc_mem[144]=5;         fc_mem[145]=66;         fc_mem[146]=-11;         fc_mem[147]=-11;         fc_mem[148]=26;         fc_mem[149]=29; 
        fc_mem[150]=-30;         fc_mem[151]=-4;         fc_mem[152]=-31;         fc_mem[153]=-67;         fc_mem[154]=-6;         fc_mem[155]=7;         fc_mem[156]=68;         fc_mem[157]=-44;         fc_mem[158]=-11;         fc_mem[159]=40; 
        fc_mem[160]=-12;         fc_mem[161]=-8;         fc_mem[162]=-71;         fc_mem[163]=13;         fc_mem[164]=3;         fc_mem[165]=-43;         fc_mem[166]=13;         fc_mem[167]=5;         fc_mem[168]=-5;         fc_mem[169]=3; 
        fc_mem[170]=-26;         fc_mem[171]=-27;         fc_mem[172]=27;         fc_mem[173]=-31;         fc_mem[174]=-8;         fc_mem[175]=11;         fc_mem[176]=-45;         fc_mem[177]=58;         fc_mem[178]=27;         fc_mem[179]=-11; 
        fc_mem[180]=26;         fc_mem[181]=36;         fc_mem[182]=5;         fc_mem[183]=65;         fc_mem[184]=30;         fc_mem[185]=-28;         fc_mem[186]=-13;         fc_mem[187]=26;         fc_mem[188]=2;         fc_mem[189]=-83; 
        fc_mem[190]=1;         fc_mem[191]=-45;         fc_mem[192]=24;         fc_mem[193]=-1;         fc_mem[194]=-31;         fc_mem[195]=-1;         fc_mem[196]=-57;         fc_mem[197]=-23;         fc_mem[198]=58;         fc_mem[199]=-50; 
        fc_mem[200]=0;         fc_mem[201]=19;         fc_mem[202]=-107;         fc_mem[203]=-8;         fc_mem[204]=-45;         fc_mem[205]=-2;         fc_mem[206]=50;         fc_mem[207]=-57;         fc_mem[208]=46;         fc_mem[209]=55; 
        fc_mem[210]=-62;         fc_mem[211]=0;         fc_mem[212]=57;         fc_mem[213]=-65;         fc_mem[214]=-52;         fc_mem[215]=57;         fc_mem[216]=-67;         fc_mem[217]=-8;         fc_mem[218]=-55;         fc_mem[219]=19; 
        fc_mem[220]=18;         fc_mem[221]=42;         fc_mem[222]=23;         fc_mem[223]=14;         fc_mem[224]=-16;         fc_mem[225]=-17;         fc_mem[226]=-13;         fc_mem[227]=25;         fc_mem[228]=53;         fc_mem[229]=-49; 
        fc_mem[230]=-18;         fc_mem[231]=7;         fc_mem[232]=51;         fc_mem[233]=-40;         fc_mem[234]=-51;         fc_mem[235]=39;         fc_mem[236]=-87;         fc_mem[237]=6;         fc_mem[238]=-8;         fc_mem[239]=19; 
        fc_mem[240]=-27;         fc_mem[241]=6;         fc_mem[242]=-18;         fc_mem[243]=0;         fc_mem[244]=-33;         fc_mem[245]=25;         fc_mem[246]=-10;         fc_mem[247]=-30;         fc_mem[248]=10;         fc_mem[249]=-18; 
        fc_mem[250]=71;         fc_mem[251]=36;         fc_mem[252]=-54;         fc_mem[253]=-9;         fc_mem[254]=16;         fc_mem[255]=-72;         fc_mem[256]=-34;         fc_mem[257]=-25;         fc_mem[258]=64;         fc_mem[259]=24; 
        fc_mem[260]=-41;         fc_mem[261]=103;         fc_mem[262]=44;         fc_mem[263]=-64;         fc_mem[264]=-29;         fc_mem[265]=27;         fc_mem[266]=-6;         fc_mem[267]=-54;         fc_mem[268]=26;         fc_mem[269]=-18; 
        fc_mem[270]=-12;         fc_mem[271]=-30;         fc_mem[272]=-40;         fc_mem[273]=41;         fc_mem[274]=54;         fc_mem[275]=-73;         fc_mem[276]=35;         fc_mem[277]=62;         fc_mem[278]=7;         fc_mem[279]=29; 
        fc_mem[280]=23;         fc_mem[281]=3;         fc_mem[282]=0;         fc_mem[283]=31;         fc_mem[284]=18;         fc_mem[285]=-86;         fc_mem[286]=-12;         fc_mem[287]=-10;         fc_mem[288]=-1;         fc_mem[289]=-70; 
        fc_mem[290]=-22;         fc_mem[291]=27;         fc_mem[292]=-79;         fc_mem[293]=5;         fc_mem[294]=8;         fc_mem[295]=-88;         fc_mem[296]=-16;         fc_mem[297]=-17;         fc_mem[298]=-4;         fc_mem[299]=25; 
        fc_mem[300]=-43;         fc_mem[301]=-16;         fc_mem[302]=-8;         fc_mem[303]=-23;         fc_mem[304]=-39;         fc_mem[305]=-11;         fc_mem[306]=37;         fc_mem[307]=0;         fc_mem[308]=45;         fc_mem[309]=116; 
        fc_mem[310]=95;         fc_mem[311]=4;         fc_mem[312]=-105;         fc_mem[313]=26;         fc_mem[314]=-15;         fc_mem[315]=-26;         fc_mem[316]=-13;         fc_mem[317]=14;         fc_mem[318]=13;         fc_mem[319]=3; 
        fc_mem[320]=24;         fc_mem[321]=4;         fc_mem[322]=6;         fc_mem[323]=-3;         fc_mem[324]=-101;         fc_mem[325]=6;         fc_mem[326]=-46;         fc_mem[327]=-55;         fc_mem[328]=-13;         fc_mem[329]=38; 
        fc_mem[330]=-30;         fc_mem[331]=30;         fc_mem[332]=64;         fc_mem[333]=-9;         fc_mem[334]=32;         fc_mem[335]=-12;         fc_mem[336]=-28;         fc_mem[337]=44;         fc_mem[338]=24;         fc_mem[339]=26; 
        fc_mem[340]=56;         fc_mem[341]=30;         fc_mem[342]=0;         fc_mem[343]=36;         fc_mem[344]=20;         fc_mem[345]=-8;         fc_mem[346]=-6;         fc_mem[347]=37;         fc_mem[348]=1;         fc_mem[349]=-38; 
        fc_mem[350]=35;         fc_mem[351]=52;         fc_mem[352]=-22;         fc_mem[353]=-39;         fc_mem[354]=-5;         fc_mem[355]=-32;         fc_mem[356]=-73;         fc_mem[357]=-56;         fc_mem[358]=14;         fc_mem[359]=4; 
        fc_mem[360]=36;         fc_mem[361]=-49;         fc_mem[362]=22;         fc_mem[363]=8;         fc_mem[364]=4;         fc_mem[365]=6;         fc_mem[366]=49;         fc_mem[367]=2;         fc_mem[368]=18;         fc_mem[369]=-68; 
        fc_mem[370]=22;         fc_mem[371]=-8;         fc_mem[372]=56;         fc_mem[373]=-89;         fc_mem[374]=-70;         fc_mem[375]=-34;         fc_mem[376]=15;         fc_mem[377]=-69;         fc_mem[378]=-64;         fc_mem[379]=-52; 
        fc_mem[380]=-70;         fc_mem[381]=6;         fc_mem[382]=-14;         fc_mem[383]=-72;         fc_mem[384]=-14;         fc_mem[385]=-23;         fc_mem[386]=-1;         fc_mem[387]=-28;         fc_mem[388]=13;         fc_mem[389]=-14; 
        fc_mem[390]=-19;         fc_mem[391]=-1;         fc_mem[392]=16;         fc_mem[393]=-10;         fc_mem[394]=42;         fc_mem[395]=2;         fc_mem[396]=-58;         fc_mem[397]=42;         fc_mem[398]=-30;         fc_mem[399]=2; 
        fc_mem[400]=52;         fc_mem[401]=-7;         fc_mem[402]=4;         fc_mem[403]=-14;         fc_mem[404]=36;         fc_mem[405]=9;         fc_mem[406]=-1;         fc_mem[407]=1;         fc_mem[408]=24;         fc_mem[409]=-25; 
        fc_mem[410]=27;         fc_mem[411]=-73;         fc_mem[412]=8;         fc_mem[413]=-37;         fc_mem[414]=-25;         fc_mem[415]=35;         fc_mem[416]=-4;         fc_mem[417]=44;         fc_mem[418]=-14;         fc_mem[419]=-59; 
        fc_mem[420]=-55;         fc_mem[421]=13;         fc_mem[422]=-25;         fc_mem[423]=-71;         fc_mem[424]=-4;         fc_mem[425]=16;         fc_mem[426]=38;         fc_mem[427]=-10;         fc_mem[428]=42;         fc_mem[429]=33; 
        fc_mem[430]=0;         fc_mem[431]=21;         fc_mem[432]=43;         fc_mem[433]=-18;         fc_mem[434]=14;         fc_mem[435]=8;         fc_mem[436]=42;         fc_mem[437]=29;         fc_mem[438]=-39;         fc_mem[439]=-4; 
        fc_mem[440]=23;         fc_mem[441]=16;         fc_mem[442]=42;         fc_mem[443]=-60;         fc_mem[444]=-46;         fc_mem[445]=21;         fc_mem[446]=-42;         fc_mem[447]=-10;         fc_mem[448]=-6;         fc_mem[449]=55; 
        fc_mem[450]=-6;         fc_mem[451]=-30;         fc_mem[452]=28;         fc_mem[453]=18;         fc_mem[454]=2;         fc_mem[455]=7;         fc_mem[456]=-84;         fc_mem[457]=18;         fc_mem[458]=-32;         fc_mem[459]=34; 
        fc_mem[460]=1;         fc_mem[461]=1;         fc_mem[462]=32;         fc_mem[463]=6;         fc_mem[464]=-52;         fc_mem[465]=-114;         fc_mem[466]=-62;         fc_mem[467]=-62;         fc_mem[468]=60;         fc_mem[469]=-36; 
        fc_mem[470]=-13;         fc_mem[471]=24;         fc_mem[472]=35;         fc_mem[473]=-30;         fc_mem[474]=-19;         fc_mem[475]=77;         fc_mem[476]=-110;         fc_mem[477]=-18;         fc_mem[478]=-33;         fc_mem[479]=-22; 

        
        // Flattening
        for (i = 0; i < 75; i = i + 1) l1_weights_flat[8*i +: 8] = l1_mem[i];
        for (i = 0; i < 225; i = i + 1) l2_weights_flat[8*i +: 8] = l2_mem[i];
        for (i = 0; i < 480; i = i + 1) fc_weights_flat[8*i +: 8] = fc_mem[i];
    end
endmodule
