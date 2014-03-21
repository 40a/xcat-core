# IBM(c) 2007 EPL license http://www.eclipse.org/legal/epl-v10.html

# You can get copycds to recognize new distro DVDs/ISOs (so that you do not have to specify -n and -a)
# by adding the disc ids to the %distnames hash below.  Follow the syntax carefully.
# Reload xcatd to have it take affect (service xcatd reload).

package xCAT::data::discinfo;

require Exporter;
@ISA=qw(Exporter);
@EXPORT=qw();
@EXPORT_OK=qw(distnames numdiscs);


%distnames = (
                 "1310229985.226287" => "centos6",
		 "1323560292.885204" => "centos6.2",
		 "1341569670.539525" => "centos6.3",#x86
		 "1362445555.957609" => "centos6.4",#x86_64
                 "1176234647.982657" => "centos5",
                 "1156364963.862322" => "centos4.4",
                 "1178480581.024704" => "centos4.5",
                 "1195929648.203590" => "centos5.1",
                 "1195929637.060433" => "centos5.1",
                 "1213888991.267240" => "centos5.2",
                 "1214240246.285059" => "centos5.2",
                 "1237641529.260981" => "centos5.3",
                 "1272326751.405938" => "centos5.5",
                 "1330913492.861127" => "centos5.8",#x86_64
                 "1357930415.252042" => "centos5.9",#x86_64
                 "1195488871.805863" => "centos4.6",
                 "1195487524.127458" => "centos4.6",
                 "1301444731.448392" => "centos5.6",
                 "1170973598.629055" => "rhelc5",
                 "1170978545.752040" => "rhels5",
                 "1192660014.052098" => "rhels5.1",
                 "1192663619.181374" => "rhels5.1",
                 "1209608466.515430" => "rhels5.2",
                 "1209603563.756628" => "rhels5.2",
                 "1209597827.293308" => "rhels5.2",
                 "1231287803.932941" => "rhels5.3", 
                 "1231285121.960246" => "rhels5.3",
                 "1250668122.507797" => "rhels5.4", #x86-64
                 "1250663123.136977" => "rhels5.4", #x86
                 "1250666120.105861" => "rhels5.4", #ppc
                 "1269262918.904535" => "rhels5.5", #ppc
                 "1269260915.992102" => "rhels5.5", #i386
                 "1269263646.691048" => "rhels5.5", #x86_64
                 "1328205744.315196" => "rhels5.8", #x86_64
                 "1354216429.587870" => "rhels5.9", #x86_64
                 "1354214009.518521" => "rhels5.9", #ppc64
                 "1378846702.129847" => "rhels5.10", #x86_64
                 "1378845049.643372" => "rhels5.10", #ppc64
                 "1285193176.460470" => "rhels6", #x86_64
                 "1285192093.430930" => "rhels6", #ppc64
                 "1305068199.328169" => "rhels6.1", #x86_64
                 "1305067911.467189" => "rhels6.1", #ppc64
                 "1321546114.510099" => "rhels6.2", #x86_64
                 "1321546739.676170" => "rhels6.2", #ppc64
		 "1339641244.734735" => "rhels6.3", #ppc64
                 "1339640147.274118" => "rhels6.3", #x86_64
                 "1339638991.532890" => "rhels6.3", #i386
                 "1359576752.435900" => "rhels6.4", #x86_64
                 "1359576196.686790" => "rhels6.4", #ppc64
                 "1384196515.415715" => "rhels6.5", #x86_64
                 "1384198011.520581" => "rhels6.5", #ppc64
		 "1285193176.593806" => "rhelhpc6", #x86_64
		 "1305067719.718814" => "rhelhpc6.1",#x86_64				
		 "1321545261.599847" => "rhelhpc6.2",#x86_64				
		 "1339640148.070971" => "rhelhpc6.3",#x86_64				
		 "1359576195.413831" => "rhelhpc6.4",#x86_64, RHEL ComputeNode
                 "1194015916.783841" => "fedora8",
                 "1194015385.299901" => "fedora8",
                 "1210112435.291709" => "fedora9",
                 "1210111941.792844" => "fedora9",
                 "1227147467.285093" => "fedora10",
                 "1227142402.812888" => "fedora10",
                 "1243981097.897160" => "fedora11", #x86_64 DVD ISO
                 "1257725234.740991" => "fedora12", #x86_64 DVD ISO
                 "1273712675.937554" => "fedora13", #x86_64 DVD ISO
                 "1287685820.403779" => "fedora14", #x86_64 DVD ISO
                 "1305315870.828212" => "fedora15", #x86_64 DVD ISO
                 "1372355769.065812" => "fedora19", #x86_64 DVD ISO
                 "1372402928.663653" => "fedora19", #ppc64 DVD ISO
                 "1386856788.124593" => "fedora20", #x86_64 DVD ISO
                 "1194512200.047708" => "rhas4.6",
                 "1194512327.501046" => "rhas4.6",
                 "1241464993.830723" => "rhas4.8", #x86-64

		 "1273608367.051780" => "SL5.5", #x86_64 DVD ISO
                "1299104542.844706" => "SL6", #x86_64 DVD ISO
                "1394111947.452332" => "pkvm2.1", # ppc64
                );
my %numdiscs = (
                "1156364963.862322" => 4,
                "1178480581.024704" => 3
                );


	1;
