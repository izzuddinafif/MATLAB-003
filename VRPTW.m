function [bestrute,biaya_minimal,Biaya,totalpinalti,TotalJarak,time] = VRPTW(n_ants,iter,qo,solar,Capacity) 

filename='jarak.xlsx'; 
distance=xlsread(filename); 
filename='demand.xlsx'; 
d=xlsread(filename); 
filename='si.xlsx'; 
si=xlsread(filename); 
filename='li.xlsx'; 
li=xlsread(filename); 
filename='ei.xlsx'; 
ei=xlsread(filename); 
time=cputime; 
distance=round(distance); 
m = n_ants; %jumlah semut
n = length(distance); %jumlah kota
e = 0.5; %evaporation coefficient
alpha=1; %pangkat untuk ants' sight
beta=3; %pangkat untuk trace's effect
%menghitung visibility
for i=1:n 
 for j=1:n 
 if distance(i,j)==0
 h(i,j)=0; 
 else
 h(i,j) = 1/distance(i,j); %inverse distance
 end
 end
end
V=40*ones(n); %kecepatan kendaraan
si=si; %waktu loading unloading
%menghitung waktu tempuh (dalam menit)
for i=1:n 
 for j=1:n 
 if distance(i,j)==0 
 T(i,j)=0; 
 else
 T(i,j)=ceil((distance(i,j)./V(i,j)).*60); 
 end
 end
end 
t=0.01*ones(n); %pheromone awal
app=[]; %rute awal
for l=1:iter 
 for i=1:m 
 app(i,1)=1; %semua semut mulai dari kota 1
 end 
 for i=1:m %untuk semua semut
 mh = h; % matriks invers jarak
 urut =2:n; 
 for j=2:n %simpul berikutnya
 random=ceil(rand*length(urut)); 
 c=urut(random); 
 urut(random)=[]; 
 app(i,j)=c; 
 t(i,c)=((1-e)*t(i,c))+(e*t(i,c)); 
 mh(:,c)=0; 
 for k=1:n; 
 q=rand; 
 if q <= qo %eksploitasi
 s=max(((t(c,:).^alpha).*(mh (c,:).^beta))); 
 app(i,j+1)=k; %penempatan semut i di simpul berikutnya
 t(c,k)=((1-e)*t(c,k))+(e*t(c,k)); %local updating
 break
 else 
 %eksplorasi
 temp=(t(c,:).^alpha).*(mh(c,:).^beta); 
 s=(sum(temp)); 
 p=(1/s).*temp; 
 s=s+p(k);
 r=rand; 
 s=0; 
 if r<s 
 app(i,j+1)=k; %penempatan semut i di simpul berikutnya
 t(c,k)=(((1-e)*t(c,k))+(e*t(c,k))); %local updating
 break
 end
 end
 end 
 end 
 app(i,n+1)=1; 
 end
%KONSTRAIN TIME WINDOWS DAN KAPASITAS
subrute=[]; 
at=app; %rute yang sudah ada
[a,b]=size(at); 
look = []; 
for hh=1:a 
 lop=1; 
 travel=0; 
 carry(hh,lop)=0; %jumla barang yang dibawa
 next=2; 
 zz2(hh,lop)=0; %jarak yang ditempuh selama perjananan dalam 1 subrute 
 travel=ei(1,1); %waktu pergi dari node sebelumnya
 penalti(hh,lop)=0; %penalti yang akan didapat 
 for cc=1:b-1 %jumlah node
 look(1,:)=at(hh,:); 
 if sum(size(look))~=0 
 nc=length(look); 
 subrute{hh,lop}(1)=1; %subrute di awali dengan node 1
 Q=Capacity; %kapasitas kendaraan
 Ti{hh,lop}(next)=travel + T(look(1,cc),look(1,cc+1)); %waktu datang ke node selanjutnya
 
 %KONSTRAIN KAPASITAS
 if carry(hh,lop)+d(look(1,cc+1))<=Q %d demand
carry(hh,lop)= carry(hh,lop)+d(look(1,cc+1)); 
subrute{hh,lop}(next)=look(1,cc+1); 
zz2(hh,lop)=zz2(hh,lop)+distance(subrute{hh,lop}(next-1),subrute{hh,lop}(next)); 
 else
subrute{hh,lop}(next)=1; 
zz2(hh,lop)=zz2(hh,lop)+distance(subrute{hh,lop}(next-1),subrute{hh,lop}(next)); 
Ti{hh,lop}(next)=travel+T(look(1,cc),look(1,cc+1)); 
lop=lop+1; 
subrute{hh,lop}(1)=1; 
travel=0; 
zz2(hh,lop)=0; 
carry(hh,lop)=d(look(1,cc)); 
next=2; 
 travel=ei(1,1); 
Ti{hh,lop}(next)=travel+ T(look(1,1),look(1,cc+1));
subrute{hh,lop}(next) = look(1,cc+1); 
zz2(hh,lop)=zz2(hh,lop)+distance(subrute{hh,lop}(next-1),subrute{hh,lop}(next)); 
carry(hh,lop)=d(look(1,cc+1)); 
 end
 
 %KONSTRAIN TIME WINDOWS
if Ti{hh,lop}(next)< ei(look(1,cc+1)) %ei(waktu buka konsumen)
 start=ei(look(1,cc+1)); 
 else 
 start=Ti{hh,lop}(next); 
 end
 
 if Ti{hh,lop}(next)>li(look(1,cc+1)) %li adalah waktu tutup konsumen
 start= Ti{hh,lop}(next); 
 penalti(hh,lop)= (abs(Ti{hh,lop}(next)-li(look(1,cc+1))))*1000; 
 end
 if cc==b-1 
subrute{hh,lop}(next)=1; 
Ti{hh,lop}(next)=travel+T(look(1,cc),look(1,cc+1)); 
 lop=lop+1; 
 travel=0; 
 zz2(hh,lop)=0; 
 end
 travel=start+si(1,look(1,cc+1)); 
 next=next+1; 
 end 
 end
end
 
%menghitung total jarak yang ditempuh
 yy2=transpose(zz2); 
 TotalJarak=sum(yy2); 
 
%menghitung total pinalti
 aa=transpose(penalti); 
 totalpinalti=sum(aa); 
 
%menghitung biaya 
 s=solar; 
 Biaya= TotalJarak.*s+totalpinalti; 
 [biaya_minimal,minIndex]=min(Biaya); 
 bestrute = subrute(minIndex,:); 
 
%Global updating
 tempT = t; 
 tNew = zeros(n); 
 sizeRoute = length(bestrute); 
 sizeSubRoute = 0; 
 for num = 1:sizeRoute 
 sizeSubRoute = length(bestrute{num}); 
 for num2 = 1:sizeSubRoute-1 
 x = bestrute{1,num}(num2); 
 y = bestrute{1,num}(num2+1); 
 tNew(x,y) = ((1-e)*t(x,y))+(e/biaya_minimal); 
 end
 end
 tempT = (1-e)*tempT; 
 tNew(tNew==0)=tempT(1,1); 
 t = tNew; 
end 
time=cputime-time;