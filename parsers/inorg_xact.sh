#!/bin/bash

BINDIR="/home/debian/live"

escape_tag_value() {
  local val="$1"
  val="${val//\\/\\\\}"   # escape backslashes
  val="${val//,/\\,}"     # escape commas
  val="${val// /\\ }"     # escape spaces
  echo "$val" | tr -cd '[:print:]' # remove funny codepoints
}

if [[ x"$1" == x || x"$2" == x || x"$3" == x || x"$4" == x ]]; then
  echo "Missing arguments: $*"
  exit 1
fi

file_to_process=$1
file_to_store=$2
installation_name=$3
instrument_name=$4

# The installation name and instrument may include spaces and other invalid
# (as dictated by InfluxDB) characters, and we cannot put "<tags>", so we have
# to clean them
installation_name=$(escape_tag_value "$installation_name")
instrument_name=$(escape_tag_value "$instrument_name")

datetime=$(cat "${file_to_process}" | tail -1 | cut -d, -f 2)
timestamp_unix=$(date -d "${datetime}" +%s%N)

S16=$(cat "${file_to_process}" | tail -1 | cut -d, -f 32)
K19=$(cat "${file_to_process}" | tail -1 | cut -d, -f 38)
Fe26=$(cat "${file_to_process}" | tail -1 | cut -d, -f 52)
Cu29=$(cat "${file_to_process}" | tail -1 | cut -d, -f 58)

write_query="inorg,installation=${installation_name},instrument=${instrument_name} S16=${S16},K19=${K19},Fe26=${Fe26},Cu29=${Cu29} ${timestamp_unix}"
echo $write_query >> "${file_to_store}.lp"

exit 0


( n=24 ; while [[ $n -le 168 ]] ; do echo $n ; cat Sample_11_26_2025__22_00_05.csv | cut -d, -f $n ; n=$((n+1)) ; echo "--"; done ) 


24
MAGNESIUM
Mg 12 (ng/m3)

--
25

Mg uncert (ng/m3)

--
26
ALUMINIUM
Al 13 (ng/m3)
461.0914
--
27

Al Uncert (ng/m3)
364.8434
--
28
SILICON
Si 14 (ng/m3)
0.0000
--
29

Si Uncert (ng/m3)
0.0000
--
30
PHOSPORUS
P 15 (ng/m3)
0.0000
--
31

P Uncert (ng/m3)
0.0000
--
32
SULPHUR
S 16 (ng/m3)
1410.5027
--
33

S Uncert (ng/m3)
94.4917
--
34
CHLORINE
Cl 17 (ng/m3)
114.5488
--
35

Cl Uncert (ng/m3)
10.7339
--
36
ARGON
Ar 18 (ng/m3)

--
37

Ar uncert (ng/m3)

--
38
POTASSIUM
 K 19 (ng/m3)
51.5458
--
39

K Uncert (ng/m3)
4.4363
--
40
CALCIUM
Ca 20 (ng/m3)
14.0438
--
41

Ca Uncert (ng/m3)
1.9941
--
42
SCANDIUM
Sc 21 (ng/m3)
0.0000
--
43

Sc Uncert (ng/m3)
0.0000
--
44
TITANIUM
Ti 22 (ng/m3)
0.9275
--
45

Ti Uncert (ng/m3)
0.8236
--
46
VANADIUM
V 23 (ng/m3)
19.8138
--
47

V Uncert (ng/m3)
1.5829
--
48
CHROMIUM
Cr 24 (ng/m3)
0.0000
--
49

Cr Uncert (ng/m3)
0.0000
--
50
MANGANESE
Mn 25 (ng/m3)
0.9639
--
51

Mn Uncert (ng/m3)
0.7773
--
52
IRON
Fe 26 (ng/m3)
74.3601
--
53

Fe Uncert (ng/m3)
5.1060
--
54
COBALT
Co 27 (ng/m3)
0.0000
--
55

Co Uncert (ng/m3)
0.0000
--
56
NICKEL
Ni 28 (ng/m3)
7.0690
--
57

Ni Uncert (ng/m3)
0.7598
--
58
COPPER
Cu 29 (ng/m3)
1.1263
--
59

Cu Uncert (ng/m3)
0.4191
--
60
ZINC
Zn 30 (ng/m3)
8.6595
--
61

Zn Uncert (ng/m3)
0.7696
--
62
GALLIUM
Ga 31 (ng/m3)
0.0000
--
63

Ga Uncert (ng/m3)
0.0000
--
64
GERMANIUM
Ge 32 (ng/m3)
0.0000
--
65

Ge Uncert (ng/m3)
0.0000
--
66
ARSENIC
As 33 (ng/m3)
0.8068
--
67

As Uncert (ng/m3)
0.3431
--
68
SELENIUM
Se 34 (ng/m3)
0.2812
--
69

Se Uncert (ng/m3)
0.3938
--
70
BROMINE
Br 35 (ng/m3)
3.5153
--
71

Br Uncert (ng/m3)
0.5755
--
72
RUBINIUM
Rb 37 (ng/m3)
0.0000
--
73

Rb Uncert (ng/m3)
0.0000
--
74
STRONTIUM
Sr 38 (ng/m3)
0.5468
--
75

Sr Uncert (ng/m3)
1.1615
--
76
YTTRIUM
Y 39 (ng/m3)
0.0000
--
77

Y Uncert (ng/m3)
0.0000
--
78
ZIRCONIUM
Zr 40 (ng/m3)

--
79

Zr Uncert (ng/m3)

--
80
NIOBIUM
Nb 41(ng/m3)
216.5861
--
81

Nb Uncert (ng/m3)
14.2308
--
82
MOLYBDENUM
Mo 42 (ng/m3)
0.0000
--
83

Mo Uncert (ng/m3)
0.0000
--
84
RUTHENIUM
Ru 44 (ng/m3)

--
85

Ru Uncert (ng/m3)

--
86
RHODIUM
Rh 45 (ng/m3)

--
87

Rh Uncert (ng/m3)

--
88
PALLADIUM
Pd 46 (ng/m3)
0.0000
--
89

Pd Uncert (ng/m3)
0.0000
--
90
SILVER
Ag 47 (ng/m3)
0.0000
--
91

Ag Uncert (ng/m3)
0.0000
--
92
CADMIUM
Cd 48 (ng/m3)
1.5467
--
93

Cd Uncert (ng/m3)
12.8255
--
94
INDIUM
In 49 (ng/m3)
0.0000
--
95

In Uncert (ng/m3)
0.0000
--
96
TIN
Sn 50 (ng/m3)
0.0000
--
97

Sn Uncert (ng/m3)
0.0000
--
98
ANTIMONY
Sb 51 (ng/m3)
0.0000
--
99

Sb Uncert (ng/m3)
0.0000
--
100
TELLURIUM
Te 52 (ng/m3)

--
101

Te Uncert (ng/m3)

--
102
IODINE
I 53 (ng/m3)

--
103

I Uncert (ng/m3)

--
104
CESIUM
Cs 55 (ng/m3)
0.0000
--
105

Cs Uncert (ng/m3)
0.0000
--
106
BARIUM
Ba 56 (ng/m3)
0.0000
--
107

Ba Uncert (ng/m3)
0.0000
--
108
LANTHANUM
La 57 (ng/m3)

--
109

La Uncert (ng/m3)

--
110
CERIUM
Ce 58 (ng/m3)

--
111

Ce Uncert (ng/m3)

--
112
PRASEODYMIUM
Pr 59 (ng/m3)

--
113

Pr Uncert (ng/m3)

--
114
NEODYMIUM
Nd 60 (ng/m3)

--
115

Nd Uncert (ng/m3)

--
116
PROMETHIUM
Pm 61 (ng/m3)

--
117

Pm Uncert (ng/m3)

--
118
SAMARIUM
Sm 62 (ng/m3)

--
119

Sm Uncert (ng/m3)

--
120
EUROPIUM
Eu 63 (ng/m3)

--
121

Eu Uncert (ng/m3)

--
122
GADOLINIUM
Gd 64 (ng/m3)

--
123

Gd Uncert (ng/m3)

--
124
TERBIUM
Tb 65 (ng/m3)

--
125

Tb Uncert (ng/m3)

--
126
DYSPROSIUM
Dy 66 (ng/m3)

--
127

Dy Uncert (ng/m3)

--
128
HOLMIUM
Ho 67 (ng/m3)

--
129

Ho Uncert (ng/m3)

--
130
ERBIUM
Er 68 (ng/m3)

--
131

Er Uncert (ng/m3)

--
132
THULIUM
Tm 69 (ng/m3)

--
133

Tm Uncert (ng/m3)

--
134
YTTERBIUM
Yb 70 (ng/m3)

--
135

Yb Uncert (ng/m3)

--
136
LUTETIUM
Lu 71 (ng/m3)

--
137

Lu Uncert (ng/m3)

--
138
HAFNIUM
Hf 72 (ng/m3)

--
139

Hf Uncert (ng/m3)

--
140
TANTALUM
Ta 73 (ng/m3)

--
141

Ta Uncert (ng/m3)

--
142
TUNGSTEN
W 74 (ng/m3)

--
143

W Uncert (ng/m3)

--
144
RHENIUM
Re 75 (ng/m3)

--
145

Re Uncert (ng/m3)

--
146
OSMIUM
Os 76 (ng/m3)

--
147

Os Uncert (ng/m3)

--
148
IRIDIUM
Ir 77 (ng/m3)

--
149

Ir Uncert (ng/m3)

--
150
PLATINUM
Pt 78 (ng/m3)
0.0000
--
151

Pt Uncert (ng/m3)
0.0000
--
152
GOLD
Au 79 (ng/m3)
0.0000
--
153

Au Uncert (ng/m3)
0.0000
--
154
MERCURY
Hg 80 (ng/m3)
0.0000
--
155

Hg Uncert (ng/m3)
0.0000
--
156
THALLIUM
Tl 81 (ng/m3)
0.0000
--
157

Tl Uncert (ng/m3)
0.0000
--
158
LEAD
Pb 82 (ng/m3)
0.3712
--
159

Pb Uncert (ng/m3)
0.5903
--
160
BISMUTH
Bi 83 (ng/m3)
0.0000
--
161

Bi Uncert (ng/m3)
0.0000
--
162
THORIUM
Th 90 (ng/m3)

--
163

Th Uncert (ng/m3)

--
164
PROTACTINIUM
Pa 91 (ng/m3)

--
165

Pa Uncert (ng/m3)

--
166
URANIUM
U 92 (ng/m3)

--
167

U Uncert (ng/m3)

--
168



--
