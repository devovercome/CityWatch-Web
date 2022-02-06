-- Initial version of schema
-- 2022.01.26
use citywatch_test
go

--таблица городов ДНР, охватываемых информационной системой "Народное Око", данные видны администраторам и модераторам 
create table cities
(
	id int primary key identity,
	name nvarchar(50)
)

--таблица районов городов ДНР, охватываемых информационной системой "Народное Око", данные видны администраторам и модераторам 
create table city_districts
(
	id int primary key identity,
	city_id int references cities(id),
	name nvarchar(64)
)

--таблица статусов пользователя, данные видны администраторам  
create table user_statuses
(
	id int primary key identity,
	name nvarchar(64) unique--(Активен,Забанен,ещё какие хз)
)

--таблица ролей пользователя, данные видны администраторам  
create table user_roles
(
	id int primary key identity,
	name nvarchar(64) unique--(Пользователь,Модератор,Администратор)
)

--таблица пользователя, данные видны самому пользователю и администраторам  
create table users
(
	id uniqueidentifier primary key,--ид пользователя(первичный ключ к таблице user_table)
	login nvarchar(64) unique,--электронная почта пользователя

	password nvarchar(128) --пароль пользователя(может можно хранить хэши паролей???) -- md5 как минимум. ширину поля подумаем еще.
)

--таблица профиля пользователя, данные видны самому пользователю, администраторам и модераторам 
create table user_profiles
(
	phoneNumber nvarchar(16) null unique
	-- TODO: 1to1
	id uniqueidentifier primary key references users(id),-- уникальный 16-значный ключ типа guid(первичный ключ к таблице user_profile)
	-- user_id uniqueidentifier references users(id),--ид пользователя(внешний ключ к таблице user_table)
	-- END TODO

	FIO nvarchar(256),
	address nvarchar(512),--текст адреса пользователя
	-- NOTE: reduntant reference, since district_id points to city.
	-- city_id int references city_table(id_city),--ид города(внешний ключ к таблице city)
	district_id int references city_districts(id),--ид района в городе(внешний ключ к таблице city_region)
	status_id int references user_statuses(id),-- ид статуса профиля пользователя(внешний ключ к таблице user_status)
	role_id int references user_roles(id),-- ид роли пользователя(внешний ключ к таблице user_role)  
	rating int--рейтинг пользователя(можно подвесить его расчёт на хранимую процедуру,которая запускается раз в час) 
)

-- данные добавления,изменения,удаления учётных записей пользователей
-- предлагаю добавлять в бд с помощью тригеров и хранить их в таблицах логов/журналов несвязанных с другими таблицами
-- что бы администратор и модераторы могли быстро получать к ним доступ при большом количестве записей

--таблица статусов заявки, данные которые видны администраторам  
create table request_status
(
	id int primary key identity,
	name nvarchar(30) unique--(Обрабатывается,Рассматривается,Исполняется,Проверяется,Выполняется,В архиве)
)

--таблица категорий заявки, данные которые видны администраторам  
create table request_category
(
	id int primary key identity,
	name nvarchar(30) unique--(В Т.З есть)
)

--таблица заявок , данные видны самому пользователю, администраторам и модераторам 
create table request
(
	id nvarchar(30) primary key,-- уникальный 30-значный ключ типа guid(первичный ключ к таблице request_table)
	user_id uniqueidentifier references users(id) null,--ид пользователя, оставившего заявку (внешний ключ к таблице user_profile)
	--если здесь будет null, то заявка анонимная

	city_district_id int references city_districts(id),--ид района местонахождения заявки в городе(внешний ключ к таблице city_region)
	latitude_coord nvarchar(32),--широта места заявки
	longitude_coord nvarchar(32),--долгота места заявки
	request_status_id int references request_status(id),-- ид статуса заявки (внешний ключ к таблице user_status)
	request_category_id int references request_category(id),-- ид категории(внешний ключ к таблице user_role) 
	dateadded date,--дата добавления заявки
	datemodified date null,--дата добавления заявки
	datedeleted date null,--дата добавления заявки
	text nvarchar(max),--текст заявки
	foto_link nvarchar(max),--ссылка на фотографии заявки(пока так,потом доработаю решение с учётом возможностей ms sql для медиа)
	video_link nvarchar(max),--ссылка на видео заявки
	rate int,--рейтинг заявки(можно подвесить его расчёт на хранимую процедуру,которая запускается при создании или редактировании заявки модератором,администратором) 
	date_rate_updated date,
	request_parent_id nvarchar(30) references request(id),-- ид родительской заявки (внешний ключ к таблице request)
)
--индексировать я пока думаю стоит две таблицы (заявки,профиль пользователей),
--так как таблица пользователь меньше профиля и её по идее дергать должны меньше в силу секретности данных,а остальные таблицы маленького размера и редко изменяться будут
--также потом добавить несколько фильтровочных индексов в эти две таблицы
--сделать кластеризованный индекс по первичному ключу(по моему можно обойтись и без них,так как предполагается рандомная генерация)
--create clustered index cl_id_user on user(id)--кластеризованный индекс по первичному ключу для таблицы user
--create nonclustered index cl_id_user on user(id)--некластеризованный индекс по первичному ключу для таблицы user
