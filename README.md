# JTKICKER/JTYIEAR FPGA core compatible with Kicker/Yie Ar Kung-fu hardware

You have in your hands a faithful reproduction of Kicker's hardware. We have analysed the PCB and extracted full schematics from it. We burnt EPROMs with specific code designed to test the custom chips functionality. The discoveries found during this process have been reported to the MAME team. So we can improve the experience in emulators where possible too.

You can show your appreciation through
* Patreon: https://patreon.com/topapate
* Paypal: https://paypal.me/topapate
* Github: https://github.com/sponsors/jotego

# Known Issues

It hasn't been possible to assess whether the INTSHOW custom chip outputs the current scan line or the current vertical scroll position, as these values are the same for over a third of the line. And it is at that time when when the INTSHOW value is easy to read, as it is when the NMI interrupt comes in. In practice, it doesn't seem to matter.

The 60.5Hz vertical frequency seems problematic in MiSTer for some screens. This could be improved using a different PLL as the base clock. For now, there is a safe 60Hz mode that can be enabled in the OSD as a fall back option.

Screen synchronization can be a problem with the original PCB too. Connecting using the OSSC (default configuration) didn't bring a stable image in my small monitors for Yie Ar Kungfu. Kicker seemed ok.

# System Comparison

Games based on 082, 083 and 503 graphic chips

Game            | Date       | ID  | Palette PROM  | 085 | PSG  | VLM5030  | Sch                         | eBay price    |     YT views      |
----------------|------------|-----|---------------|-----|------|----------|-----------------------------|---------------|-------------------| 
Mega Zone       |       1983 | No  |  Only output  | No  | x1   | No       | Yes, only 083               |25€            |10.614(2016)       |
Yie Ar Kungfu   |19/Nov/1984 |GX407|  Only output  | No  | 74689| Yes      | Yes, only 082,083           |15€ cart       |3.6 M (2013) NES   |
Shaolin's Road  |22/Mar/1985 |GX477| All elements  | Yes | 74689| No       | Yes                         |97.13€         |27.664(2018)       |
Track'n Field   |10/Oct/1983 | No  | All elements  | No  |      | Yes      | Partial-Blurred             |7 a 60€ cart   |2.7 M (2015) NES   |
Hyper Sports    |31/May/1984 | No  | All elements  | Yes |      | Yes      | Yes blurred,with labels     |80€            |41.562(2012)       |
Road Fighter    |            |     |               |     |      |          | No                          |15 a 70€ cart  |4 M (2010) NES     |
Super Basketball|       1984 |GX405| All elements  | Yes | 74689| Yes      | Yes,with labels             |159€           |23.494 (2014)      |
Mikie           |15/Nov/1984 | No  | All elements  | Yes |      | No       | Yes,with labels, small      |11€     cart   |50.381 (2010)      |
Pandora's Palace|       1984 | No  | Only output   | Yes |      | No       | Yes,with labels             |      €        |14.167 (2010)      |
Ping Pong       |            |     |               |     |      |          | No                          |60€            |8.530 (2012) NES   |
Roc'n Rope      |       1984 | No  | Only output   | No  | 8910 | No       | Yes, only 082,083           |350€PCB 50€cart|43.873 (2011)      |

# Test Mode

* Super Basketball test mode is enabled by holding 1P and 2P while the game boots

# Acknowledgement

This development has been possible thanks to the board donated by yeahbuddy and the following patrons:

Adam Leslie          Adam Small           Adam Zorzin          Adrian Labastida    
Alan Shurvinton      Alda Alesio          Alexander Lash       Alexander Upton     
Alfonso Clemente     Alvaro Paniagua      Andrea Chiavazza     Andreas Micklei     
Andrew Boudreau      Andrew Hannan        Andrew P Gibson      Andrew Schmidt      
Angelfred            Angelo Kanaris       Anselmo Moreno       Anthony Monaco      
Antoine Mariette     Anton Gale           Antwon               Aquijacks (Flashjacks
Arend Pronk          Arthur Blough        Arthur Fung          Aurich Lawson       
BRCDEvg              Banane               Bear S               Ben Toman           
Bitmap Bureau        Bitmaps Retro        Bliz 452             Brandon Peach       
Brandon Smith        Brandon Thomas       Brent Fraser         Brian Peek          
Brian Plummer        Bruno M              Bryan Evans          C                   
Cameron Tinker       Carrboroman          Cesar Sandoval       Charles             
Chris Chung          Chris D              Chris Mzhickteno     Chris Tuckwell      
Chris W Miller       Chris smith          Christian Bailey     Clinton Cronin      
Cobra Clips          Colin Colehour       Colt83               DARK WEB DANGer     
Dan Doyle            Daniel               Daniel Casadevall    Daniel Dongil       
Daniel Fowler        Daniel Page          Daniel Tibi          Daniel Zetterman    
Darren Newman        Darren Wootton       Daryll David         Dasutin             
Dave Test            David Drury          David Filskov        David Fleetwood     
David Jones          Denis Brækhus        Denny Letourneau     Diana Carolina      
Didgeridoo           Didier Touron        Dimitris Zongas      Dr Catjail          
Dr. Octagon          DrMnike              Dre137               Eren Kotan          
Eric Gutt            Eric J Faulkes       Fabio Michelin       Federico            
Five Year Guy        Florian Raoult       GeorgeSpinner        Gluthecat           
GohanX               Goolio               Grant McNaught       Greg                
Greg Sargent         Gregory Val          HFSPlay              Handheld Obsession  
Henry                Henry R              Hentai Joe           Hugo Pinto          
ItsBobDudes          JOSE LUIS            JR                   Jack Sammons        
Jacob Hoffman        Jacob Lawter         James Dingo          James Kilgore       
Jeff Roberts         Jeremy Hasse         Jerry Suggs          Jesse Clark         
Jim Knowler          JimLahey             Jimmy Dozier         Jimmy Richards      
Jockel               Joel Albino          Johan Smolinski      John Figueroa       
John Fletcher        John Hood            John Silva           John T. Keen        
John Wilson          Johnny harvick       Jonah Phillips       Jonathan            
Jonathan Brochu      Jonathan Loor        Jonathan Tuttle      Joost Peters        
Jootec from          Jorge                Jork Sonkinfield     Jose L              
Joseph Kulinski      Joseph Milazzo       Joseph Mogavero      Josh Emery          
Josh Mayer           Josh Yates-Walker    Josiah Wilson        Justin D'Arcangelo  
Kai Cherry           Kai Luotojoki        Keith Gordon         Kem Yos             
Ken Scott            Kevin Gudgeirsson    KnC                  Kricys              
KrzysFR              L.Rapter             Lakeside             Laurent Cooper      
Lee Grocott          Lee Osborne          Luis F Giron         MaDDoG              
Mack H               Madox                Magnus Kvevlander    Manuel Astudillo    
Marco Emparan        Mark                 Mark Baffa           MarthSR             
Martin Ansin         Matt Elder           Matt Evans           Matt Lichtenberg    
Matt McCarthy        Matt Postema         Matthew Woodford     MechaGG             
Michael Anderson     Michael Berger       Michael C            Michael Eggers      
Michael Ferguson     Michael Rea          Michael_DKT          Mike Holzinger      
Mike Jegenjan        Mike Olson           Mike Parks           Mottzilla           
My War               Nailbomb             Narugawa             Neil St Clair       
NerdyNester          Nic Kaiman           Nick Delia           Nick Gudauskas      
Nico Stamp           Nicolas Hurtado      Niko                 NonstopXiaowei      
Norman Wehrle        OopsAllBerrys        Oriez                Oskar Sigvardsson   
Pascal Courtois      Patrick Roman        Paul                 Paul Cunningham     
Paul Hoggett         Paulo M.             Paweł Mandes         PeFClic             
Pedro Santiago       Per Ole              Philip Lai           Philip Lawson       
Piafoman             Pierre-Emmanuel Martin Pontus Nyholm        Rachael Netz        
Rachel Schaeffer     RandomRetro          Raul3D               RayGun              
RetroRGB             Rex Kung             Richard Eng          Richard Murillo     
Richard Simpson      Rick Ochoa           Riyad Twair          Robert Daniel       
Romain Dijoux        Ronald Dean          Ronan Amicel         Ruben               
Ryan                 Ryan O'Malley        Sam Hall             Samuel Warner       
Sang Hee             Sascha Zupanek       Schnookums           Shannon King        
Simon Osborne        Spank Minister       SteelRush            Stefan Krueger      
Stephen R Price      Steve Ikeguchi       Steve Lin            Steve Skrzyniarz    
Steve Tack           Steven Hansen        Steven Yedwab        Stuart Morton       
Sunder Raj           SuperBabyHix         Syrotuck             Taehyun Kim         
Taiki Hosoda         Tales Dilli          Terse                The Collector       
The Video            TheLevelOfDetail .   Thomas Attanasio     Thomas Irwin        
Thorias              Timothy Bearup       Tobias Dossin        Tom Milner          
Travis Brown         Trifle               Turboman UK          Ty B                
VickiViperZabel      Victor Bly           Victor Fontanez      Will Abbott         
William Clemens      Yunus Soğukkanlı     Zach Marquette       Zoltan Kovacs       
albertprime          alejandro carlos     angel_killah         arcadebros          
benedict lindley     blackwine            brian burney         cbab                
chauviere benjamin   circletheory         datajerk             deathr0w            
deathwombat          gunmakuma            jbrlll               joshewah777         
kamel rasennadja     kccheng              kernelchagi          keropi              
liphy                meng po              metal                natalie             
nonamebear           pacoarcade           patrick pejic        qzxcvbn             
retrod00d            rsn8887              slayer213            taal.M              
tonitellezb          troy coberly         turbochop3300        type78              
yoaarond             
