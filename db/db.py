from pymongo import MongoClient
from dotenv import load_dotenv
import os 
load_dotenv()  
db_client = MongoClient(os.getenv("DB_CLIENT"))
db = db_client.ProyectoPrincipios