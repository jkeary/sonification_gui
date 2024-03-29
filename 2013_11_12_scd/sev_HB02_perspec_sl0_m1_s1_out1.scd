

/*
HEADER 

variables provided by soniscan++, include given detune percentage, deviation values, and name of the output file

both : [p,q,r] --> new variable names [~bF,~bMC,~bP]
left : [t,u,v] --> new variable names [~lF,~lMC,~lP]
right : [x,y,z] --> new variable names [~rF,~rMC,~rP]
OUTPUT string of file name : ~output
*/

// Next steps: Make it an external program.

(
~bF = -0.236494;
~bMC = 0;
~bP = -0.294044;
~lF = -0.258245;
~lMC = 0;
~lP = -0.262113;
~rF = -0.214742;
~rMC = 0;
~rP = -0.325975;
~output = "sev_HB02_perspec_sl0_m1_s1";


// some more variables not passed in from soniscan++
~lastplayed = nil;
~basefreq = 440; // base frequency

~tail = ".wav";
// var inpath;
// inpath = PathName.new("/Users/jameskeary/Dropbox/Sonification/Soni_GUI"); 
// inpath.files.postln;
~outpath = "/Users/jameskeary/Desktop/Soni_GUI/output";  // where recorded files go
~imgpath = "~/Desktop/Soni_GUI/images/";  // where images come from
i = SCImage.new(~imgpath ++ ~output.subStr(0,15) ++ "_img.png");

// Starting case
// find the worst case from the left and right hemispheres and the both hemisphere numbers.  To do so find the case with the greatest range of deviation 
~leftabs = abs(~lMC-~lF) + abs(~lMC-~lP);
~rightabs = abs(~rMC-~rF) + abs(~rMC-~rP); 
~bothabs = abs(~bMC -~bF) + abs(~bMC-~bP);
~array = [~leftabs, ~rightabs, ~bothabs];
switch (~array.maxItem.asString,
	~leftabs.asString, {~thewrst = "left"; ~wF = ~lF; ~wMC = ~lMC; ~wP = ~lP;},
	~rightabs.asString, {~thewrst = "right"; ~wF = ~rF; ~wMC = ~rMC; ~wP = ~rP;},
	~bothabs.asString, {~thewrst = "both"; ~wF = ~bF; ~wMC = ~bMC; ~wP = ~bP;},
);
// start compression value is 
~compression = 10; // default positive deviation compression value (1, so 1:1, i.e. no compression)

// starting detune values are 
if (~output.at(0)++~output.at(1) == "no") {~detune1 =  0.05};
if (~output.at(0)++~output.at(1) == "mi") {~detune1 =  0.1};
if (~output.at(0)++~output.at(1) == "mo") {~detune1 =  0.15};
if (~output.at(0)++~output.at(1) == "se") {~detune1 =  0.2};
~detune2 = ~detune1; // detune value 2

// Start the server
Server.default = s = Server.internal.boot; // GOTTA USE INTERNAL SERVER FOR SCOPE
//s.scope(2);
//s.freqscope;
//s.meter;

// SynthDefs onto server
(
	SynthDef.new(\Tri, { 
			arg freq1 = 0, freq2 = 0, amp1 = 0, amp2 = 0;
			Out.ar(0, LFTri.ar([[freq1], [freq2]], 0, [[amp1], [amp2]]));
			};
	);
).send(s);

(
	SynthDef.new(\Sine, { 
			arg freq1 = 0, freq2 = 0, amp1 = 0, amp2 = 0;
			Out.ar(0, SinOsc.ar([[freq1],[freq2]], 0, [[amp1], [amp2]]));
			};
	);
).send(s);

(
	SynthDef.new(\Saw, { 
			arg freq1 = 0, freq2 = 0, amp1 = 0, amp2 = 0;
			Out.ar(0, LFSaw.ar([[freq1],[freq2]], 0, [[amp1]/2, [amp2]/2]));
			};
	);
).send(s);

(
	SynthDef.new(\Square, { 
			arg freq1 = 0, freq2 = 0, amp1 = 0, amp2 = 0;
			Out.ar(0, LFPulse.ar([[freq1],[freq2]], 0, 0.5, [[amp1], [amp2]], 0));
			};
	);
).send(s);


(
	SynthDef.new(\Off, { 
			arg freq1 = 0, freq2 = 0, amp1 = 0, amp2 = 0;
			Out.ar(0, LFPulse.ar([[freq1],[freq2]], 0, 0.5, [[amp1], [amp2]], 0));
			};
	);
).send(s);

// initialize synths with default values
a = Synth.new(\Tri, [freq1:0,freq2:0,amp1:0,amp2:0]).run(false);
~aPlaying = false;
b = Synth.new(\Tri, [freq1:0,freq2:0,amp1:0,amp2:0]).run(false);
~bPlaying = false;
c = Synth.new(\Tri, [freq1:0,freq2:0,amp1:0,amp2:0]).run(false);
~cPlaying = false;

// important function that is used over and over again!!!
~computefreqs = Routine.new({ 
// find which deviations are in use
	~hemisphere = case
			{((~playleft.value == 1) || (~recleft.value == 1) || (~lastplayed == "playing left") || (~lastplayed == "rec left") 
				|| ((~playworst.value == 1) || (~recworst.value == 1) || (~lastplayed == "playing worst") || (~lastplayed == "rec worst") && (~thewrst == "left")))} {"left"}
			{((~playboth.value == 1) || (~recboth.value == 1) || (~lastplayed == "playing both") || (~lastplayed == "rec both") || (~lastplayed == nil)
				|| ((~playworst.value == 1) || (~recworst.value == 1) || (~lastplayed == "playing worst") || (~lastplayed == "rec worst") && (~thewrst == "both")))} {"both"}
			{((~playright.value == 1) || (~recright.value == 1) || (~lastplayed == "playing right") || (~lastplayed == "rec right")
	 			|| ((~playworst.value == 1) || (~recworst.value == 1) || (~lastplayed == "playing worst") || (~lastplayed == "rec worst") && (~thewrst == "right")))} {"right"}; 
	if (~hemisphere == "left") { ~dev1 = ~lF; ~dev2 = ~lMC; ~dev3 = ~lP; };
	if (~hemisphere == "both") { ~dev1 = ~bF; ~dev2 = ~bMC; ~dev3 = ~bP; };
	if (~hemisphere == "right") { ~dev1 = ~rF; ~dev2 = ~rMC; ~dev3 = ~rP; };
// if positive deviation, send through compressor
	if (~dev1.isPositive) {~dev1 = ~dev1/~compression;};
	if (~dev3.isPositive) {~dev3 = ~dev3/~compression;};
// send deviations through inversions
	if (~flipf.value == 1) {~dev1 = -1*~dev1;};
	if (~flipp.value == 1) {~dev3 = -1*~dev3;};	 
	~cboxF.value_(~dev1);
	~cboxP.value_(~dev3);
// send freqs thru detuners
	~ffreq = (~dev1*(~detune1)*~basefreq)+~basefreq;
	~pfreq = (~dev3*(~detune2)*~basefreq)+~basefreq;
	~numbox1.value = ~ffreq;
	~numbox3.value = ~pfreq;	
// where to route?
	if (~spreadLCR.value == 1) { ~aamp1 = 0.2; ~aamp2 = 0; ~bamp1 = 0.1; ~bamp2 = 0.1; ~camp1 = 0; ~camp2 = 0.2; 
		~textbox.string = ~lastplayed ++ " is now sending frontal freq left, motor cortex center, and parietal right"; } 
	{ if ((~playleft.value == 1) || (~recleft.value == 1) || (~lastplayed == "playing left") || (~lastplayed == "rec left"))
		{~aamp1 = 0.2; ~aamp2 = 0; ~bamp1 = 0.2; ~bamp2 = 0; ~camp1 = 0.2; ~camp2 = 0; ~textbox.string=~lastplayed; };
	if ((~playboth.value == 1) || (~recboth.value == 1) || (~lastplayed == "playing both") || (~lastplayed == "rec both") || (~lastplayed == nil))
		{~aamp1 = 0.2; ~aamp2 = 0.2; ~bamp1 = 0.2; ~bamp2 = 0.2; ~camp1 = 0.2; ~camp2 = 0.2; ~textbox.string=~lastplayed; }; 
	if ((~playworst.value == 1) || (~recworst.value == 1) || (~lastplayed == "playing worst") || (~lastplayed == "rec worst"))
		{~aamp1 = 0.2; ~aamp2 = 0.2; ~bamp1 = 0.2; ~bamp2 = 0.2; ~camp1 = 0.2; ~camp2 = 0.2; ~textbox.string= ~lastplayed ++ ", "++ ~thewrst ++ " is the worst";};
	if ((~playright.value == 1) || (~recright.value == 1) || (~lastplayed == "playing right") || (~lastplayed == "rec right"))
		{~aamp1 = 0; ~aamp2 = 0.2; ~bamp1 = 0; ~bamp2 = 0.2; ~camp1 = 0; ~camp2 = 0.2; ~textbox.string=~lastplayed; };
	};

// send values to oscillators
	if (~menuF.value == 4) {a.set(\freq1, 0, \freq2, 0, \amp1, 0, \amp2, 0);} {a.set(\freq1, ~ffreq, \freq2, ~ffreq, \amp1, ~aamp1, \amp2, ~aamp2);};
	if (~menuMC.value == 4) {b.set(\freq1, 0, \freq2, 0, \amp1, 0, \amp2, 0);} {b.set(\freq1, ~basefreq, \freq2, ~basefreq, \amp1, ~bamp1, \amp2, ~bamp2);};
	if (~menuP.value == 4) {c.set(\freq1, 0, \freq2, 0, \amp1, 0, \amp2, 0);} {c.set(\freq1, ~pfreq, \freq2, ~pfreq, \amp1, ~camp1, \amp2, ~camp2);};	
});

~recordRoutine = Routine.new({
	~recrec = ~lastplayed.at(4);
	s.recSampleFormat = 'int16';
	s.recHeaderFormat = 'wav';
	s.prepareForRecord(~outpath++"/"++~output.subStr(0,16)++~recrec++"c_d"++~detune1++"_f"++~ffreq++"_p"++~pfreq++~tail);
	wait(0.2);
	s.record;
	wait(30);
	s.stopRecording;	
	a.run(false);
	b.run(false);
	c.run(false);
	if (~recleft.value == 1) {~recleft.value_(0)}; 		if (~recright.value == 1) {~recright.value_(0)}; 	
	if (~recboth.value == 1) {~recboth.value_(0)}; 	
	if (~recworst.value == 1) {~recworst.value_(0)}; 
});

// GUI WINDOW
~window = SCWindow(~output, Rect(1,200,515, 565));
~window.view.background_(Color.grey);
~window.view.decorator = ~flowlayout = FlowLayout(~window.view.bounds);
~window.front;
	
// BUTTONS
// PLAY LEFT BUTTON
~playleft = SCButton(~window, Rect(0, 0, 123, 24))
	.states_([["Play Left", Color.black, Color.new255(199, 199, 199)],["Stop Left", Color.black, Color.red]])
	.action_({
		arg butt; 
		var ber; 
		ber = butt.value;
		if( ber == 1 ) {	
			~lastplayed = "playing left";
			~textbox.string=~lastplayed;
			~computefreqs.play(AppClock);
			~oscil1 = ~menuF.item;
			~oscil2 = ~menuMC.item;
			~oscil3 = ~menuP.item;
			a.run(true);
			~aPlaying = true;
			b.run(true);
			~bPlaying = true;
			c.run(true);
			~cPlaying = true;
		};
		if (( ber == 0 ) || (~lastplayed != "playing left")) {
// turn off oscilators
			~textbox.string = "";	
			~computefreqs.stop(AppClock);
			~computefreqs.reset(AppClock);
			if (~aPlaying == true) { a.run(false); ~aPlaying = false; };
			if (~bPlaying == true) { b.run(false); ~bPlaying = false; };
			if (~cPlaying == true) { c.run(false); ~cPlaying = false; };
			};
	});			

//PLAY BOTH BUTTON
~playboth = SCButton(~window, Rect(0, 0, 123, 24))
	.states_([["Play Both", Color.black, Color.new255(199, 199, 199)],["Stop Both", Color.black, Color.red]])
	.action_({
		arg butt;
		var ber; 
		ber = butt.value;
		if( ber == 1 ) {
			~lastplayed = "playing both";
			~textbox.string=~lastplayed;
			~computefreqs.play(AppClock);
			~oscil1 = ~menuF.item;
			~oscil2 = ~menuMC.item;
			~oscil3 = ~menuP.item;
			a.run(true);
			~aPlaying = true;
			b.run(true);
			~bPlaying = true;
			c.run(true);
			~cPlaying = true;
		};
		if (( ber == 0) || (~lastplayed != "playing both")) {
// turn off oscilators
			~textbox.string = "";	
			~computefreqs.stop(AppClock);
			~computefreqs.reset(AppClock);
			if (~aPlaying == true) { a.run(false); ~aPlaying = false; };
			if (~bPlaying == true) { b.run(false); ~bPlaying = false; };
			if (~cPlaying == true) { c.run(false); ~cPlaying = false; };
		};
	});						
				
			
//PLAY RIGHT BUTTON
~playright = SCButton(~window, Rect(0, 0, 123, 24))
	.states_([["Play Right", Color.black, Color.new255(199, 199, 199)],["Stop Right", Color.black, Color.red]])
	.action_({
		arg butt;
		var ber; 
		ber = butt.value;
		if( ber == 1 ) {
			~lastplayed = "playing right";
			~textbox.string=~lastplayed;
			~computefreqs.play(AppClock);
			~oscil1 = ~menuF.item;
			~oscil2 = ~menuMC.item;
			~oscil3 = ~menuP.item;
			a.run(true);
			~aPlaying = true;
			b.run(true);
			~bPlaying = true;
			c.run(true);
			~cPlaying = true;
		};
		if((ber == 0) || (~lastplayed != "playing right")) {
// turn off oscilators
			~textbox.string = "";	
			~computefreqs.stop(AppClock);
			~computefreqs.reset(AppClock);
			if (~aPlaying == true) { a.run(false); ~aPlaying = false; };
			if (~bPlaying == true) { b.run(false); ~bPlaying = false; };
			if (~cPlaying == true) { c.run(false); ~cPlaying = false; };
		};
	});	

//PLAY WORST REGION BUTTON
~playworst = SCButton(~window, Rect(0, 0, 123, 24))
	.states_([["Play Worst", Color.black, Color.new255(199, 199, 199)],["Stop Worst", Color.black, Color.red]])
	.action_({
		arg butt;
		var ber; 
		ber = butt.value;
		if( ber == 1 ) {
			~lastplayed = "playing worst";
			~computefreqs.play(AppClock);
			~oscil1 = ~menuF.item;
			~oscil2 = ~menuMC.item;
			~oscil3 = ~menuP.item;
			a.run(true);
			~aPlaying = true;
			b.run(true);
			~bPlaying = true;
			c.run(true);
			~cPlaying = true;
		};
		if ((ber == 0) || (~lastplayed != "playing worst")) {
// turn off oscilators
			~textbox.string = "";
			~computefreqs.stop(AppClock);
			~computefreqs.reset(AppClock);	
			if (~aPlaying == true) { a.run(false); ~aPlaying = false; };
			if (~bPlaying == true) { b.run(false); ~bPlaying = false; };
			if (~cPlaying == true) { c.run(false); ~cPlaying = false; };
		};
	});	

//RECORDING LEFT
~recleft = SCButton(~window, Rect(0, 0, 123, 24))
	.states_([["Rec Left", Color.black, Color.new255(199, 199, 199)],["Stop Rec", Color.black, Color.red]])
	.action_({
		if ( ~recleft.value == 1 ) {
			~lastplayed = "rec left";
			~textbox.string=~lastplayed;
			~computefreqs.stop(AppClock);
			~computefreqs.reset(AppClock);
			~computefreqs.play(AppClock);
			~oscil1 = ~menuF.item;
			~oscil2 = ~menuMC.item;
			~oscil3 = ~menuP.item;
			a.run(true);
			~aPlaying = true;
			b.run(true);
			~bPlaying = true;
			c.run(true);
			~cPlaying = true;					
			// record for 30 seconds
			~recordRoutine.stop(AppClock);
			~recordRoutine.reset(AppClock);
			~recordRoutine.play(AppClock);
		};
		if ((~recleft.value == 0) || (~lastplayed != "rec left")) {
// turn off oscilators, stop recording
			~textbox.string = "";
			s.stopRecording;	
			~computefreqs.stop(AppClock);
			~computefreqs.reset(AppClock);
			~recordRoutine.stop(AppClock);
			~recordRoutine.reset(AppClock);
			if (~aPlaying == true) { a.run(false); ~aPlaying = false; };
			if (~bPlaying == true) { b.run(false); ~bPlaying = false; };
			if (~cPlaying == true) { c.run(false); ~cPlaying = false; };
		};
	});	
			
// RECORDING BOTH
~recboth = SCButton(~window, Rect(0, 0, 123, 24))
	.states_([["Rec Both", Color.black, Color.new255(199, 199, 199)],["Stop Rec", Color.black, Color.red]])
	.action_({
		if( ~recboth.value == 1 ) {
			~lastplayed = "rec both";
			~textbox.string=~lastplayed;
			~computefreqs.stop(AppClock);
			~computefreqs.reset(AppClock);
			~computefreqs.play(AppClock);
			~oscil1 = ~menuF.item;
			~oscil2 = ~menuMC.item;
			~oscil3 = ~menuP.item;
			a.run(true);
			~aPlaying = true;
			b.run(true);
			~bPlaying = true;
			c.run(true);
			~cPlaying = true;					
			// record for 30 seconds
			~recordRoutine.stop(AppClock);
			~recordRoutine.reset(AppClock);
			~recordRoutine.play(AppClock);
		};
		if ((~recboth.value == 0) || (~lastplayed != "rec both")) {
			~textbox.string = "";
// turn off oscilators, stop recording
			s.stopRecording;
			~computefreqs.stop(AppClock);
			~computefreqs.reset(AppClock);	
			~recordRoutine.stop(AppClock);
			~recordRoutine.reset(AppClock);
			if (~aPlaying == true) { a.run(false); ~aPlaying = false; };
			if (~bPlaying == true) { b.run(false); ~bPlaying = false; };
			if (~cPlaying == true) { c.run(false); ~cPlaying = false; };
		};
	});	

//RECORDING RIGHT		
~recright = SCButton(~window, Rect(0, 0, 123, 24))
	.states_([["Rec Right", Color.black, Color.new255(199, 199, 199)],["Stop Rec", Color.black, Color.red]])
	.action_({
		if( ~recright.value == 1 ) {
			~lastplayed = "rec right";
			~textbox.string=~lastplayed;
			~computefreqs.stop(AppClock);
			~computefreqs.reset(AppClock);
			~computefreqs.play(AppClock);
			~oscil1 = ~menuF.item;
			~oscil2 = ~menuMC.item;
			~oscil3 = ~menuP.item;
			a.run(true);
			~aPlaying = true;
			b.run(true);
			~bPlaying = true;
			c.run(true);
			~cPlaying = true;
			// record for 30 seconds
			~recordRoutine.stop(AppClock);
			~recordRoutine.reset(AppClock);
			~recordRoutine.play(AppClock);
		};
		if ((~recright.value == 0) || (~lastplayed != "rec right")) {
			~textbox.string = "";
// turn off oscilators, stop recording
			s.stopRecording;	
			~computefreqs.stop(AppClock);
			~computefreqs.reset(AppClock);
			~recordRoutine.stop(AppClock);
			~recordRoutine.reset(AppClock);
			if (~aPlaying == true) { a.run(false); ~aPlaying = false; };
			if (~bPlaying == true) { b.run(false); ~bPlaying = false; };
			if (~cPlaying == true) { c.run(false); ~cPlaying = false; };
		};
	});	

//RECORDING WORST		
~recworst = SCButton(~window, Rect(0, 0, 123, 24))
	.states_([["Rec Worst", Color.black, Color.new255(199, 199, 199)],["Stop Rec", Color.black, Color.red]])
	.action_({
		if( ~recworst.value == 1) {
			~lastplayed = "rec worst";
			~textbox.string=~lastplayed ++ ", " ++ ~thewrst ++ " is the worst region";
			~computefreqs.stop(AppClock);
			~computefreqs.reset(AppClock);
			~computefreqs.play(AppClock);
			~oscil1 = ~menuF.item;
			~oscil2 = ~menuMC.item;
			~oscil3 = ~menuP.item;
			a.run(true);
			~aPlaying = true;
			b.run(true);
			~bPlaying = true;
			c.run(true);
			~cPlaying = true;
			// record for 30 seconds	
			~recordRoutine.stop(AppClock);
			~recordRoutine.reset(AppClock);		
			~recordRoutine.play(AppClock);
		};
		if ((~recworst.value == 0) || (~lastplayed != "rec worst")) {
			~textbox.string = "";
// turn off oscilators, stop recording
			s.stopRecording;	
			~computefreqs.stop(AppClock);
			~computefreqs.reset(AppClock);
			~recordRoutine.stop(AppClock);
			~recordRoutine.reset(AppClock);
			if (~aPlaying == true) { a.run(false); ~aPlaying = false; };
			if (~bPlaying == true) { b.run(false); ~bPlaying = false; };
			if (~cPlaying == true) { c.run(false); ~cPlaying = false; };
		};
	});	
				
// MESSAGE BOX
~textbox = SCTextField(~window, Rect(1, 1, 505, 20))
	.align_(\center).stringColor_(Color.yellow)
	.background_(Color.new255(0, 0, 139));

~flowlayout.nextLine;

// BRAIN SCAN IMAGE
~window.drawFunc_({i.drawInRect(Rect(10,90,500,500), Rect(10,10,1200,1200), 2, 1.0)});

96.do({ ~flowlayout.nextLine; });

// FREQUENCY VALUES DISPLAY

// Frontal
~ffreq = (~wF*(~detune1)*~basefreq)+~basefreq; //calculate "worst" first to display initially
SCStaticText(~window, Rect(130, 60, 45, 20))
	.string_("Frontal:")
	.stringColor_(Color.black);
~numbox1 = SCNumberBox(~window, Rect(20, 20, 90, 20))
	.string_(~ffreq)
	.stringColor_(Color.yellow)
	.background_(Color.new255(0, 0, 139))
	.action_({ ~ffreq = ~numbox1.value; a.set(\freq1, ~ffreq, \freq2, ~ffreq); });

~flipf = SCButton(~window, Rect(0, 0, 25, 20))
	.states_([["Inv", Color.black, Color.new255(199, 199, 199)],["Inv", Color.black, Color.red]])
	.action_({ 
		~computefreqs.stop(AppClock);
		~computefreqs.reset(AppClock);
		~computefreqs.play(AppClock);
	});
// Starting inversion
if (~wF.isPositive) {~flipf.value = 1};
		
// Motor Cortex
SCStaticText(~window, Rect(130, 60, 80, 20))
	.string_("Motor Cortex:")
	.stringColor_(Color.black);
~numbox2 = SCNumberBox(~window, Rect(20, 20, 30, 20))
	.stringColor_(Color.yellow).background_(Color.new255(0, 0, 139))
	.action_({ 
		// user input
		~basefreq = ~numbox2.value;
		b.set(\freq1, ~basefreq, \freq2, ~basefreq); 
		~computefreqs.stop(AppClock);
		~computefreqs.reset(AppClock);
		~computefreqs.play(AppClock);
	});
~numbox2.string = ~basefreq;

// Parietal

~pfreq = (~wP*(~detune2)*~basefreq)+~basefreq;

SCStaticText(~window, Rect(130, 60, 50, 20)).string_("Parietal:").stringColor_(Color.black);
~numbox3 = SCNumberBox(~window, Rect(20, 20, 90, 20)).string_(~pfreq).stringColor_(Color.yellow).background_(Color.new255(0, 0, 139))
	.action_({ ~pfreq = ~numbox3.value; c.set(\freq1, ~pfreq, \freq2, ~pfreq); });
	
~flipp = SCButton(~window, Rect(0, 0, 25, 20)).states_([["Inv", Color.black, Color.new255(199, 199, 199)],["Inv", Color.black, Color.red]])
	.action_({ 
		~computefreqs.stop(AppClock);
		~computefreqs.reset(AppClock);
		~computefreqs.play(AppClock);
	});
// Starting inversion
if (~wP.isNegative) {~flipp.value = 1};
	
// STEREO SPREAD BUTTON - SEND FRONTAL LEFT, MOTOR CORTEX CENTER, PARIETAL RIGHT
~spreadLCR = SCButton(~window, Rect(0, 0, 40, 20)).states_([["LCR", Color.black, Color.new255(199, 199, 199)],["off", Color.black, Color.red]])
	.action_({
		~computefreqs.stop(AppClock);
		~computefreqs.reset(AppClock);
		~computefreqs.play(AppClock);
	});

// FRONTAL DETUNE VALUE AND SLIDER
SCStaticText(~window, Rect(130, 60, 60, 20))
	.string_("Detune 1:")
	.stringColor_(Color.black);
~slider1 = SCSlider(~window, Rect(20,100,90,20))
	.background_(Color.red)
	.value_(~detune1.linlin(0.025, 0.20, 0, 1))
	.action_({~dbox1.value_(~slider1.value)})
	.action_({
		~detune1 = ~slider1.value.linlin(0,1,0.025,0.2);
		~dbox1.string_(~detune1.value.asString);
		~computefreqs.stop(AppClock);
		~computefreqs.reset(AppClock);
		~computefreqs.play(AppClock);
	});
~dbox1 = SCNumberBox(~window, Rect(20, 20, 90, 20))
	.stringColor_(Color.yellow)
	.background_(Color.new255(0, 0, 139));
~dbox1.string = ~detune1;

// PARIETAL DETUNE VALUE AND SLIDER
SCStaticText(~window, Rect(130, 60, 60, 20))
	.string_("Detune 2:")
	.stringColor_(Color.black);
~slider2 = SCSlider(~window, Rect(20,100,90,20))
	.background_(Color.red)
	.value_(~detune2.linlin(0.025, 0.20, 0, 1))
	.action_({~dbox2.value_(~slider2.value)})
	.action_({
		~detune2 = ~slider2.value.linlin(0,1,0.025,0.2);
		~dbox2.string_(~detune2.value.asString);
		~computefreqs.stop(AppClock);
		~computefreqs.reset(AppClock);
		~computefreqs.play(AppClock);
	});
~dbox2 = SCNumberBox(~window, Rect(20, 20, 90, 20))
	.stringColor_(Color.yellow)
	.background_(Color.new255(0, 0, 139));
~dbox2.string = ~detune2;

// OSCILLATORS
SCStaticText(~window, Rect(130, 60, 63, 20)).string_("Oscillators:")
	.stringColor_(Color.black);

SCStaticText(~window, Rect(130, 60, 60, 20)).string_("Frontal:")
	.stringColor_(Color.black);
~menuF=SCPopUpMenu(~window,Rect(10,10,70,20))
	.stringColor_(Color.yellow)
	.background_(Color.new255(0, 0, 139))
	.items_([ "Tri", "Sine" , "Saw" , "Square", "Off"])
	.action_(
		{arg synthType; 
			synthType = synthType.value;
			a.free;
			~computefreqs.stop(AppClock);
			~computefreqs.reset(AppClock);
			~computefreqs.play(AppClock);
			a = case
				{ synthType == 0 } { Synth.new(\Tri, [freq1:~ffreq,freq2:~ffreq,amp1:~aAmp1,amp2:~aAmp2]).run(~aPlaying); }
				{ synthType == 1 } { Synth.new(\Sine, [freq1:~ffreq,freq2:~ffreq,amp1:~aAmp1,amp2:~aAmp2]).run(~aPlaying); }
				{ synthType == 2  } { Synth.new(\Saw, [freq1:~ffreq,freq2:~ffreq,amp1:~aAmp1,amp2:~aAmp2]).run(~aPlaying); }
				{ synthType == 3  } { Synth.new(\Square, [freq1:~ffreq,freq2:~ffreq,amp1:~aAmp1,amp2:~aAmp2]).run(~aPlaying); }
				{ synthType == 4  } { Synth.new(\Tri, [freq1:0,freq2:0,amp1:0,amp2:0]).run(~aPlaying); };
		};
	);
				
SCStaticText(~window, Rect(130, 60, 80, 20))
	.string_("Motor Cortex:").stringColor_(Color.black);
~menuMC=SCPopUpMenu(~window,Rect(10,10,70,20))
	.stringColor_(Color.yellow)
	.background_(Color.new255(0, 0, 139))
	.items_([ "Tri", "Sine" , "Saw" , "Square", "Off"])
	.action_(
		{arg synthType; 
			synthType = synthType.value;
			b.free;
			~computefreqs.stop(AppClock);
			~computefreqs.reset(AppClock);
			~computefreqs.play(AppClock);
			b = case
				{ synthType == 0 } Ê { Synth.new(\Tri, [freq1:~basefreq,freq2:~basefreq,amp1:~bAmp1,amp2:~bAmp2]).run(~bPlaying); }
				{ synthType == 1 } { Synth.new(\Sine, [freq1:~basefreq,freq2:~basefreq,amp1:~bAmp1,amp2:~bAmp2]).run(~bPlaying); }
				{ synthType == 2  } { Synth.new(\Saw, [freq1:~basefreq,freq2:~basefreq,amp1:~bAmp1,amp2:~bAmp2]).run(~bPlaying); }
				{ synthType == 3  } { Synth.new(\Square, [freq1:~basefreq,freq2:~basefreq,amp1:~bAmp1,amp2:~bAmp2]).run(~bPlaying); }
				{ synthType == 4  } { Synth.new(\Tri, [freq1:0,freq2:0,amp1:0,amp2:0]).run(~bPlaying); };
		};
	);
				
SCStaticText(~window, Rect(130, 60, 60, 20)).string_("Parietal:").stringColor_(Color.black);
~menuP=SCPopUpMenu(~window,Rect(10,10,70,20))
	.stringColor_(Color.yellow)
	.background_(Color.new255(0, 0, 139))
	.items_([ "Tri", "Sine" , "Saw" , "Square", "Off"])
	.action_(
		{arg synthType; 
			synthType = synthType.value;
			c.free;
			~computefreqs.stop(AppClock);
			~computefreqs.reset(AppClock);
			~computefreqs.play(AppClock);
			c = case
				{ synthType == 0 } Ê { Synth.new(\Tri, [freq1:~pfreq,freq2:~pfreq,amp1:~cAmp1,amp2:~cAmp2]).run(~cPlaying); }
				{ synthType == 1 } { Synth.new(\Sine, [freq1:~pfreq,freq2:~pfreq,amp1:~cAmp1,amp2:~cAmp2]).run(~cPlaying); }
				{ synthType == 2  } { Synth.new(\Saw, [freq1:~pfreq,freq2:~pfreq,amp1:~cAmp1,amp2:~cAmp2]).run(~cPlaying); }
				{ synthType == 3  } { Synth.new(\Square, [freq1:~pfreq,freq2:~pfreq,amp1:~cAmp1,amp2:~cAmp2]).run(~cPlaying); }
				{ synthType == 4  } { Synth.new(\Tri, [freq1:0,freq2:0,amp1:0,amp2:0]).run(~cPlaying); };
		};
	);
	
// DEVIATION COMPRESSOR FOR COMPRESSION OF THE VALUES WITH POSITIVE DEVIATION
SCStaticText(~window, Rect(0, 0, 210, 20))
	.string_("Positive Deviation Compression Ratio:")
	.stringColor_(Color.black);
~ratiobox = SCNumberBox(~window, Rect(0, 0, 33, 20))
	.string_("1:" ++ ~compression)
	.stringColor_(Color.yellow)
	.background_(Color.new255(0, 0, 139));
~slider3 = SCSlider(~window, Rect(20,100,90,20))
	.background_(Color.red)
	.step_(0.05)
	.value_(~compression.linlin(1, 20, 0, 1))
	.action_({
		~ratiobox.value_(~slider3.value);
		~compression = ~slider3.value.linlin(0,1,1,20);
		~ratiobox.string_("1:" ++ ~compression.value.asInteger);
		~computefreqs.stop(AppClock);
		~computefreqs.reset(AppClock);
		~computefreqs.play(AppClock);
	});
SCStaticText(~window, Rect(0, 0, 10, 20))
	.string_("F:")
	.stringColor_(Color.black);
~cboxF = SCNumberBox(~window, Rect(0, 0, 62, 20))
	.string_(~wF)
	.stringColor_(Color.yellow)
	.background_(Color.new255(0, 0, 139));
SCStaticText(~window, Rect(0, 0, 11, 20))
	.string_("P:")
	.stringColor_(Color.black);	
~cboxP = SCNumberBox(~window, Rect(0, 0, 62, 20))
	.string_(~wP)
	.stringColor_(Color.yellow)
	.background_(Color.new255(0, 0, 139));

// CLOSING TIME
~window.onClose_{ s.free; i.free; CmdPeriod.removeAll; };
)
