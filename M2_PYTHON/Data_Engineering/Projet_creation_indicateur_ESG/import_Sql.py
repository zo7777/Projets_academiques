import sqlalchemy
import pandas as pd

conso_elec = pd.read_csv("Data//Conso_elec.csv",sep=",")
conso_elec = pd.melt(conso_elec, id_vars=['Country Name', 'Country Code', 'Indicator Name', 'Indicator Code'],
                    var_name='year', value_name="Conso_elec_KWh_hbt")
conso_elec = conso_elec[['Country Name','Country Code', 'year', 'Conso_elec_KWh_hbt']]
conso_elec = conso_elec.sort_values(by=['Country Code', 'year'])

emission = pd.read_csv("Data//Emission_CO2.csv",sep=",")
emission = pd.melt(emission, id_vars=['Country Name', 'Country Code', 'Indicator Name', 'Indicator Code'],
                    var_name='year', value_name="Emission_CO2_tonnes_hbt")
emission = emission[['Country Name','Country Code', 'year', 'Emission_CO2_tonnes_hbt']]
emission = emission.sort_values(by=['Country Code', 'year'])

Pib_hbt = pd.read_csv("Data//PIB_HBT.csv",sep=",")
Pib_hbt = pd.melt(Pib_hbt, id_vars=['Country Name', 'Country Code', 'Indicator Name', 'Indicator Code'],
                    var_name='year', value_name="Pib_hbt")
Pib_hbt = Pib_hbt[['Country Name','Country Code', 'year', 'Pib_hbt']]
Pib_hbt = Pib_hbt.sort_values(by=['Country Code', 'year'])

Pib = pd.read_csv("Data//Pib.csv",sep=",",header=4)
Pib = pd.melt(Pib, id_vars=['Country Name', 'Country Code', 'Indicator Name', 'Indicator Code'],
                    var_name='year', value_name="Pib_dollars")
Pib = Pib[['Country Name','Country Code', 'year', 'Pib_dollars']]
Pib = Pib.sort_values(by=['Country Code', 'year'])

Pop_active = pd.read_csv("Data//Pop_active.csv",sep=",")
Pop_active = pd.melt(Pop_active, id_vars=['Country Name', 'Country Code', 'Indicator Name', 'Indicator Code'],
                    var_name='year', value_name="Population_active")
Pop_active = Pop_active[['Country Name','Country Code', 'year', 'Population_active']]
Pop_active = Pop_active.sort_values(by=['Country Code', 'year'])

Pop_active_femme = pd.read_csv("Data//Pop_active_femme.csv",sep=",")
Pop_active_femme = pd.melt(Pop_active_femme, id_vars=['Country Name', 'Country Code', 'Indicator Name', 'Indicator Code'],
                    var_name='year', value_name="Pourcentage_femme_active")
Pop_active_femme = Pop_active_femme[['Country Name','Country Code', 'year', 'Pourcentage_femme_active']]
Pop_active_femme = Pop_active_femme.sort_values(by=['Country Code', 'year'])

database_username = '***'
database_password = '***'
database_ip       = 'localhost'
database_name     = 'Projet_data_eng'
database_connection = sqlalchemy.create_engine('mysql+mysqlconnector://{0}:{1}@{2}/{3}'.
                                               format(database_username, database_password, 
                                                      database_ip, database_name))
                                                    
conso_elec.to_sql(con=database_connection, name='Conso_elec', if_exists='replace')
Pib.to_sql(con=database_connection, name='PIB', if_exists='replace')
emission.to_sql(con=database_connection, name='Emission_CO2', if_exists='replace')
Pib_hbt.to_sql(con=database_connection, name='Pib_hbt', if_exists='replace')
Pop_active.to_sql(con=database_connection, name='Pop_active', if_exists='replace')
Pop_active_femme.to_sql(con=database_connection, name='Pourcentage_femmes_actives', if_exists='replace')
