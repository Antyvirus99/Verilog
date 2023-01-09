module przerzutnik(clk,T,q);
input T,clk;
output reg q;
always @(posedge clk)
begin
	q=T;
end
endmodule

module dioda(zmiana,stan,clk);
	input zmiana;
	output stan;
	input clk;
	reg temp=0;
	assign stan =temp;
	always @(posedge clk)begin
		if(zmiana == 1)
		begin
			temp = 1;
		end
		if(zmiana == 0)
		begin
			temp = 0;
		end
	end
endmodule

module licznik(wlacznik,y,czas,clk);
input clk,wlacznik;
input wire [7:0] czas;
reg[15:0] i =0;
output wire y;
reg temp =0;
assign y = temp;
always @(posedge clk)begin
	if(wlacznik == 1) begin
	i=i+1;
	end
	else temp = 0;
	if (i>=czas) begin
		temp =1;
		i=0;
	end
end
endmodule

module przycisk(wejscie,wyjscie,clk);
input clk;
input wejscie;
output wyjscie;
reg temp = 0;
assign wyjscie = temp;
always @(posedge clk)begin
	if (wejscie==1) begin
		temp =1;
	end
	else temp = 0;
	
end
endmodule

module zmien_stan(x,y,z,clk);
input clk;
input wire x,y;
output z;
reg temp=0;
assign z= temp;
always @(posedge clk) begin
	if(x == 1 && y==0) begin temp = 1; end
	else if(y==1) begin
	temp = 0;
	end
	else temp = 0;
end
endmodule

module zbocze(clk,wejscie,wyjscie);
input clk;
input wejscie;
output wire [1:0] wyjscie;
//1 zbocze narastajace, 2 zbocze opadajce, 0 zbocze stale
reg[1:0] temp;
reg[1:0] temp2;
reg raz=0;
assign wyjscie = temp2;
always @(posedge clk)begin
	//pierwsze zbocze narastające
	if(wejscie ==1 && raz ==0) begin
		raz=1;
		temp=1;
		temp2=1;
		end
	else if(wejscie ==0 && temp ==1) begin
		temp=2;
		temp2=2;
		end
	else if(wejscie==1 && temp ==2)begin
		temp=1;
		temp2=1;
	end
	else temp2=0;
end

endmodule

module program;
reg clk=0;
always #1 clk = !clk;
reg wlacznik_licznika=1;
wire zmiana_licznika;
reg wejscie_przycisku1 =0;
reg wejscie_przycisku2 =0;
reg zmiana_przycisku;
wire zmiana_przycisku1a,zmiana_przycisku2a;
wire zmiana_przycisku1,zmiana_przycisku2;
reg [7:0]przerwa = 12;
reg [15:0] sekundy =0;
reg [15:0] czas =0;
reg [31:0]seed = 50;
reg new_seed=0;
reg[15:0] czas_sumaryczny=0;
integer los;
reg wybor_diody=0;
reg zmiana1,zmiana2;
reg reset =0;
reg[15:0] liczba_podejsc=0;

//licznik odliczajacy czas do zapalenia diody
licznik licznik(wlacznik_licznika,zmiana_licznika,przerwa,clk);

//wlacznik/wylacznik diody
zmien_stan zmien_stan(zmiana_licznika,zmiana_przycisku,zmiana,clk);

przycisk przycisk1(wejscie_przycisku1,zmiana_przycisku1a,clk);
przerzutnik przerzutnik1 (clk,zmiana_przycisku1a,zmiana_przycisku1);

przycisk przycisk2(wejscie_przycisku2,zmiana_przycisku2a,clk);
przerzutnik przerzutnik2 (clk,zmiana_przycisku2a,zmiana_przycisku2);

dioda dioda1(zmiana1,stan1,clk);
dioda dioda2(zmiana2,stan2,clk);
 

//wylaczenie licznika kiedy przycisk jest wcisniety. Czas zacznie byc liczony od momentu zwolnienia przycisku

zbocze zmiana_przycisku_zbocze(clk,zmiana_przycisku, zmiana_przycisku_flag);
zbocze zmiana_przycisku1_zbocze(clk,zmiana_przycisku1,zmiana_przycisku1_flag);
zbocze zmiana_przycisku2_zbocze(clk,zmiana_przycisku2,zmiana_przycisku2_flag);
zbocze stan1_zbocze(clk,stan1,stan1_flag);
zbocze stan2_zbocze(clk,stan2,stan2_flag);
zbocze reset_zbocze(clk,reset,reset_flag);
//stoper
always @(posedge clk) begin
czas_sumaryczny=czas_sumaryczny+1;
	if(stan1==1 || stan2==1) sekundy = sekundy +1;
	if((stan1== 0 && sekundy !=0 && wybor_diody ==0)||(stan2== 0 && sekundy !=0 && wybor_diody ==1))begin
		czas = sekundy;
		new_seed =1;
		sekundy =0;
	end
	//nowy seed. Dla symulatora ta linijka w praktyce nie ma sensu.
	//Wartosci sa zbyt male i seed praktycznie się nie zmienia, przez co przerwa miedzy kolejnymi stanami diody szybko dazy do 1
	//Mialoby to sens gdyby testy odbywaly sie w rzeczywistosci gdzie roznice czasu beda znacznie bardziej roznorodne.
	//Dla zoobrazowania problemu wysylam program "generator"
	
	//if(new_seed ==1)begin seed = czas; new_seed=0; end
	
	//ustawienie konkretnej diody do wlaczenia
	//dioda 1
	if(wybor_diody == 0 && zmiana == 1) zmiana1=1; //on
	if(wybor_diody == 0 && zmiana == 0) zmiana1=0; //off
	if(wybor_diody == 0 && zmiana_przycisku1 == 0) zmiana_przycisku=0; //zwolnienie przycisku
	//dioda 2
	if(wybor_diody == 1 && zmiana == 1) zmiana2=1; //on
	if(wybor_diody == 1 && zmiana == 0) zmiana2=0; //off
	if(wybor_diody == 1 && zmiana_przycisku2 == 0) zmiana_przycisku=0; //zwolnienie przycisku
	
	//wylaczenie licznika kiedy przycisk jest wcisniety. Czas zacznie byc liczony od momentu zwolnienia przycisku
	if(zmiana_przycisku1_flag==2||zmiana_przycisku2_flag==2) wlacznik_licznika=1;
	if(zmiana_przycisku_flag==1)wlacznik_licznika = 0;
	
	//losowanie przerwy miedzy zaswieceniem diody
	if(zmiana_przycisku_flag==1)begin
		wlacznik_licznika = 0;
		los=$random(seed);
		przerwa = los%256 +1;
	end
	//zliczanie podejsc 
	if(zmiana_przycisku1_flag==1||zmiana_przycisku2_flag==1)begin
		if(wybor_diody == 0 && zmiana_przycisku1 == 1)begin
			zmiana_przycisku=1;
			liczba_podejsc =liczba_podejsc+1;
		end
		if(wybor_diody == 0 && zmiana_przycisku2 == 1)begin
			liczba_podejsc =liczba_podejsc+1;
		end
		if(wybor_diody == 1 && zmiana_przycisku2 == 1)begin
			zmiana_przycisku=1;
			liczba_podejsc =liczba_podejsc+1;
		end
		if(wybor_diody == 1 && zmiana_przycisku1 == 1)begin
			liczba_podejsc =liczba_podejsc+1;
		end
	end
	
	if(stan1_flag==2||stan2_flag==2)wybor_diody = $random%2+1;
	
	if(reset_flag==1)begin
		czas_sumaryczny=0;
		czas=0;
		liczba_podejsc =0;
	end
end

initial begin
$monitor("dioda0_stan %d \t dioda1_stan %d \t ktora dioda jest zapalona %d \t czas pomiedzy kolejnymi zapaleniami diod %d \t  liczba podejsc %d \t laczny czas",stan1,stan2,wybor_diody,przerwa,liczba_podejsc,czas,czas_sumaryczny);
/*#30 wejscie_przycisku1=1;
#10 wejscie_przycisku1 =0;
#15 wejscie_przycisku2=1;
#12 wejscie_przycisku2 =0;
#150 wejscie_przycisku1=1;
#10 wejscie_przycisku1=0;
#50 $finish;*/
end
endmodule