% Stephen Muggleton's Prolog code for
% randomly generating Michalski trains.
% adopted by Lukas Helff
% To run this you need a Prolog interpreter which executes
% a goal of the form:
% R is random
% Otherwise replace the definition of random/2 appropriately.
% (``R is random '' binds R to a pseudo-random number--floating
% point--between 0 and 1.)
% The top-level predicates are trains/0 and trains/1.
% modified for SWI-Prolog by Lukas Helff

loop(0).
loop(N_trains) :- N_trains>0, trains, C_train is N_trains-1, loop(C_train).

trains :- train1(X), show(X).


% trains :- repeat, train1(X), show(X),rep.

% rep :- (get_counter == 5 ->
%   writeln('all trains generated'),
%    ! % cut, we won't backtrack to repeat anymore
% ;
%   writeln('repeat train generation'),
%   increment,
%   repeat % backtrack to repeat
% ).


% rep :- write('More (y/n)? '), read(n),nl,
% (n == y ->
%   writeln('You selected yes.'),
%   repeat % backtrack to repeat
% ; writeln('You selected no.'),
%   ! % cut, we won't backtrack to repeat anymore
% ).

trains([]) :- !.
trains([H|T]) :- train1(H), trains(T), !.
train1(Carriages) :-
  random([0,0.3,0.3,0.4],NCarriages),
  length(Carriages,NCarriages),
  carriages(Carriages,1), !.

carriages([],_).
carriages([C|Cs],N) :-
  carriage(C,N), N1 is N+1,
  carriages(Cs,N1), !.

carriage(c(N,Shape,Length,Double,Roof,Wheels,Load),N) :-
  randprop(car_length,[0.7,0.3],Length),
  shape(Length,Shape),
  double(Length,Shape,Double),
  roof1(Length,Shape,Roof),
  wheels(Length,Wheels),
  load(Length,Load), !.

shape(long,rectangle).
shape(short,S) :-
  randprop(car_shape,[0.048,0.048,0.524,0.190,0.190],S).

double(short,rectangle,Double) :-
  randprop(car_double,[0.73,0.27],Double), !.
double(_,_,not_double) :- !.

roof1(short,ellipse,arc) :- !.
roof1(short,hexagon,flat) :- !.
roof1(short,_,R) :- randprop(roof_shape,[0.842,0.105,0,0.053,0],R).
roof1(long,_,R) :- randprop(roof_shape,[0.333,0.444,0.223,0,0],R).

wheels(short,2).
wheels(long,W) :- random([0,0.56,0.44],W).

load(short,l(Shape,N)) :-
  randprop(load_shape,[0.381,0.048,0,0.190,0.381,0],Shape),
  random([0.952,0.048],N).

load(long,l(Shape,N)) :-
  randprop(load_shape,[0.125,0,0.125,0.625,0,0.125],Shape),
  random([0.11,0.55,0.11,0.23],N1), N is N1-1.

random(Dist,N) :-
  %R is random
  % R is 1,
  random(0,1.0,R),
  random(1,0,R,Dist,N).

random(N,_,_,[_],N).
random(N,P0,R,[P|_],N) :-
  P1 is P+P0, R=<P1, !.
random(N,P0,R,[P|Rest],M) :-
  P1 is P+P0, N1 is N+1,
  random(N1,P1,R,Rest,M), !.

randprop(Prop,Dist,Value) :-
  random(Dist,R),
  Call=..[Prop,R,Value],
  Call, !.

car_shape(1,ellipse). car_shape(2,hexagon).
car_shape(3,rectangle). car_shape(4,u_shaped). car_shape(5,bucket).
car_length(1,short). car_length(2,long).
car_open(1,open). car_open(2,closed).
car_double(1,not_double). car_double(2,double).
roof_shape(1,none). roof_shape(2,flat). roof_shape(3,jagged).
roof_shape(4,peaked). roof_shape(5,arc).
load_shape(1,circle). load_shape(2,diamond). load_shape(3,hexagon).
load_shape(4,rectangle). load_shape(5,triangle). load_shape(6,utriangle).

show(Train) :-
  direction(Train),
  show0(Train),
  open('MichalskiTrains.txt', append, OS),
  format(OS, "~n" , []),
  close(OS),
  nl, !.

show0([]).
show0([C|Cs]) :-
  C=c(N,Shape,Length,Double,Roof,Wheels,l(Lshape,Lno)),
  open('MichalskiTrains.txt', append, OS),
  format(OS, ' ~w ~w ~w ~w ~w ~w ~w ~w', [N,Shape,Length,Double,Roof,Wheels,Lno,Lshape]),
  writes(['Car ',N,': Shape = ',Shape,
  ', Length = ',Length,', Double = ',Double,nl, tab(8),
  'Roof = ',Roof,
  ', Wheels = ',Wheels,
  ', Load = ',Lno,' of ',Lshape,nl]),
  close(OS),
  show0(Cs), !.

direction(Train) :-
  open('MichalskiTrains.txt', append, OS),
  (eastbound(Train) -> (format(OS, "~w" , [east]), write('Eastbound train:'), nl)
  ;otherwise -> (format(OS, "~w" , [west]), write('Westbound train:'), nl)),
  close(OS).

writes([]).
writes([H|T]) :-
  mywrite(H),
  writes(T).

mywrite(nl) :- nl, !.
mywrite(tab(X)) :- tab(X), !.
mywrite(X) :- write(X), !.

% Concept tester below emulates Michalski predicates.

% Theory X
% There is either a short, closed car, or a car with a circular load somewhere behind a car with a triangular load.
eastbound([Car|Cars]):-
(short(Car), closed(Car));
(has_load0(Car,triangle), has_load1(Cars,circle));
eastbound(Cars).


has_car(T,C) :- member(C,T).

infront(T,C1,C2) :- append(_,[C1,C2|_],T).

ellipse(C) :- arg(2,C,ellipse). hexagon(C) :- arg(2,C,hexagon).

rectangle(C) :- arg(2,C,rectangle). u_shaped(C) :- arg(2,C,u_shaped).

bucket(C) :- arg(2,C,bucket).

long(C) :- arg(3,C,long). short(C) :- arg(3,C,short).

double(C) :- arg(4,C,double).

has_roof(C,r(R,N)) :- arg(1,C,N), arg(5,C,R).

open(C) :- arg(5,C,none). closed(C) :- not(open(C)).

has_wheel(C,w(NC,W)) :- arg(1,C,NC), arg(6,C,NW), nlist(1,NW,L), member(W,L).

has_load(C,Load) :- arg(7,C,l(_,NLoad)), nlist(1,NLoad,L), member(Load,L).

has_load0(C,Shape) :- arg(7,C,l(Shape,N)), 1=<N.

has_load1(T,Shape) :- has_car(T,C), has_load0(C,Shape).

none(r(none,_)). flat(r(flat,_)).
jagged(r(jagged,_)). peaked(r(peaked,_)).
arc(r(arc,_)).

member(X,[X|_]).
member(X,[_|T]) :- member(X,T).

nlist(N,N,[N]) :- !.
nlist(M,N,[M|T]) :-
  M=<N,
  M1 is M+1, nlist(M1,N,T), !.

len1([],0) :- !.
len1([_|T],N) :- len1(T,N1), N is N1+1, !.

append([],L,L) :- !.
append([H|L1],L2,[H|L3]) :-
  append(L1,L2,L3), !.

% Prolog representation of 20 trains.


% eastbound([c(1,rectangle,short,not_double,none,2,l(circle,1)),c(2,rectangle,
%   long,not_double,none,3,l(hexagon,1)),c(3,rectangle,short,
%   not_double,peaked,2,l(triangle,1)),c(4,rectangle,long,
%   not_double,none,2,l(rectangle,3))]).
%
% eastbound([c(1,rectangle,short,not_double,flat,2,l(circle,2)),c(2,bucket,
%   short,not_double,none,2,l(rectangle,1)),c(3,u_shaped,
%   short,not_double,none,2,l(triangle,1))]).
%
% eastbound([c(1,rectangle,long,not_double,flat,3,l(utriangle,1)),c(2,hexagon,
%   short,not_double,flat,2,l(triangle,1)),c(3,rectangle,
%   short,not_double,none,2,l(circle,1))]).
%
% eastbound([c(1,rectangle,short,not_double,none,2,l(rectangle,1)),c(2,ellipse,
%   short,not_double,arc,2,l(diamond,1)),c(3,rectangle,short,
%   double,none,2,l(triangle,1)),c(4,bucket,short,not_double,
%   none,2,l(triangle,1))]).
%
% eastbound([c(1,rectangle,short,not_double,flat,2,l(circle,1)),c(2,rectangle,
%   long,not_double,flat,3,l(rectangle,1)),c(3,rectangle,
%   short,double,none,2,l(triangle,1))]).
%
% eastbound([c(1,rectangle,long,not_double,jagged,3,l(rectangle,1)),c(2,hexagon,
%   short,not_double,flat,2,l(circle,1)),c(3,rectangle,short,
%   not_double,none,2,l(triangle,1)),c(4,rectangle,long,not_double,
%   jagged,2,l(rectangle,0))]).
%
% eastbound([c(1,rectangle,long,not_double,none,2,l(hexagon,1)),c(2,rectangle,
%   short,not_double,none,2,l(rectangle,1)),c(3,rectangle,
%   short,not_double,flat,2,l(triangle,1))]).
%
% eastbound([c(1,rectangle,short,not_double,peaked,2,l(rectangle,1)),c(2,
%   bucket,short,not_double,none,2,l(rectangle,1)),c(3,rectangle,
%   long,not_double,flat,2,l(circle,1)),c(4,rectangle,short,
%   not_double,none,2,l(rectangle,1))]).
%
% eastbound([c(1,rectangle,long,not_double,none,2,l(rectangle,3)),c(2,rectangle,
%   short,not_double,none,2,l(circle,1)),c(3,rectangle,long,
%   not_double,jagged,3,l(hexagon,1)),c(4,u_shaped,short,
%   not_double,none,2,l(triangle,1))]).
%
% eastbound([c(1,bucket,short,not_double,none,2,l(triangle,1)),c(2,u_shaped,
%   short,not_double,none,2,l(circle,1)),c(3,rectangle,short,
%   not_double,none,2,l(triangle,1)),c(4,rectangle,short,
%   not_double,none,2,l(triangle,1))]).
