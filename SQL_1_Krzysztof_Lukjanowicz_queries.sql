/*Jakie są miasta, w których mieszka więcej niż 3 pracowników?*/  

select city
from employees e
group by city
having count(employee_id)>3

/*Zakładając, że produkty, które kosztują (UnitPrice) mniej niż 10$
możemy uznać za tanie, te między 10$ a 50$ za średnie, a te powyżej
50$ za drogie, ile produktów należy do poszczególnych przedziałów?*/  

select 
	case 
		when unit_price < 10 then 'tanie'
		when unit_price between 10 and 50 then 'srednie'
		when unit_price > 50 then 'drogie'
	end as price_group,
	count(product_id) as Quantity
from products p
group by
	case
		when unit_price < 10 then 'tanie'
		when unit_price between 10 and 50 then 'srednie'
		when unit_price > 50 then 'drogie'
	end
order by 1 desc


/*Czy najdroższy produkt z kategorii z największą średnią ceną to
najdroższy produkt ogólnie?*/ 

with cte as
(
	select
			(
			select distinct first_value(product_id) over (order by unit_price desc)
			from products
			where
				category_id = (
								select category_id
								from products
								group by category_id
								order by avg(unit_price) desc
								limit 1
								)
			) as from_category,
			(
			select product_id
			from products
			where
				unit_price = (
								select max(unit_price)
								from products p2
								)
			) as expensive
)
select
		from_category as most_expensive_from_most_expensive_category,
		case
				when expensive = from_category
				then 'is most expensive product'
				else 'is not most expensive, more expensive is'
				end,
		expensive as most_expensive_product
from cte

/*Ile kosztuje najtańszy, najdroższy i ile średnio kosztuje produkt od
każdego z dostawców? UWAGA – te dane powinny być przedstawione
z nazwami dostawców, nie ich identyfikatorami*/

select
	s.company_name,
	min(p.unit_price) as price_of_cheapest,
	max(p.unit_price) as price_of_most_expensive,
	avg(p.unit_price) as average_price
from
	products p
	left join suppliers s on s.supplier_id = p.supplier_id
group by
	s.company_name


/*Jak się nazywają i jakie mają numery kontaktowe wszyscy dostawcy i
klienci (ContactName) z Londynu? Jeśli nie ma numeru telefonu,
wyświetl faks.*/

select
	contact_name,
	coalesce(phone,fax) as contact_number
from suppliers s
where city = 'London'

union

select
	contact_name,
	coalesce(phone,fax)
from customers c
where city = 'London'


/*Które miejsce cenowo (od najtańszego) zajmują w swojej kategorii
(CategoryID) wszystkie produkty?*/

select
	rank() over (partition by category_id order by unit_price) as place,
	product_id,
	product_name,
	category_id,
	unit_price
from products p


/*Jaka była i w jakim kraju miała miejsce najwyższa dzienna amplituda
temperatury?*/  

select
	maxtemp - mintemp as max_temperature_amplitude,
	wsl."STATE/COUNTRY ID"
from
	summary_of_weather sow
left join weather_station_locations wsl on wsl.wban = sow.sta
where
	maxtemp - mintemp = (
							select
								max(maxtemp - mintemp)
							from
								summary_of_weather sow2
							)

/*Z czym silniej skorelowana jest średnia dzienna temperatura dla stacji
– szerokością (lattitude) czy długością (longtitude) geograficzną?*/  


select
	corr(sow.meantemp, wsl.latitude) correlation_latitude,
	corr(sow.meantemp, wsl.longitude) correlation_longitude,
	corr(sow.meantemp, abs(wsl.latitude)) correlation_latitude_absolute --merytorycznie lepiej, jako oddalenie od rownika
from summary_of_weather sow
left join weather_station_locations wsl on wsl.wban = sow.sta


/*Pokaż obserwacje, w których suma opadów atmosferycznych
(precipitation) przekroczyła sumę opadów z ostatnich 5 obserwacji na
danej stacji.*/ 


with cleaning as (
				select
					replace(precip, 'T', '0.0001')::numeric
					----trace is more than 0 so I use 0,0001
					+ case
						when snowfall = '' then 0
						else replace(snowfall, '#VALUE!', '0')::numeric
					end	as precipitation_clean
				,*
				from
					summary_of_weather sow
),
calculating as (
				select
					case
						when precipitation_clean >
						coalesce(sum(precipitation_clean) over (partition by sta order by "Date" rows between 5 preceding and 1 preceding), 0)
						then 1
						else 0
					end as greater_than_5_preceding,
					row_number() over (partition by sta	order by "Date") as observation_number,
					--for filtering out 5 observations without enough preceding
					*
				from
					cleaning
)
select
	*
from
	calculating
where
	observation_number > 5
	and greater_than_5_preceding = 1



