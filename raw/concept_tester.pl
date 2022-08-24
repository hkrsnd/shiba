

%eastbound([Car|Cars]):-
%  (short(Car), closed(Car));
%  (has_load0(Car,triangle), has_load1(Cars,circle));
%  eastbound(Cars).

%eastbound(Train):-
%    (has_car(Train,Car), closed(Car), (double(Car); bucket(Car)));
%    (has_car(Train,Car), load_num(Car,3), has_wheel(Car,w(NC,3))).

eastbound(A) :-
   has_car(A,B,1), has_car(A,C,2), has_car(A,D,3), car_color(D,yellow),
   car_color(C,yellow), car_color(B,yellow), has_wheel0(D,2), has_wheel0(C,3),
   has_wheel0(B,3), has_roof0(D,none), has_roof0(C,solid_roof), has_roof0(B,none).

