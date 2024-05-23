import io
import time
from fastapi import FastAPI, HTTPException
from db.db import db
from db.models.user import user, userLogin
from db.schemas.user import user_schema
import bcrypt
import json
from fastapi import Depends, FastAPI, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from jose import JWTError, jwt
from passlib.context import CryptContext
from datetime import datetime, timedelta
from openai import OpenAI
from typing import Optional
from fastapi import HTTPException, FastAPI
from fastapi.responses import StreamingResponse
from openai import AssistantEventHandler
from typing_extensions import override
from PIL import Image
from fastapi import FastAPI, Request, HTTPException, UploadFile, File, Form
from queue import Queue
import google.generativeai as genai
import tempfile
from dotenv import load_dotenv
import os
import uuid
from bson.objectid import ObjectId 

import google.ai.generativelanguage as glm

import base64

load_dotenv()  

app = FastAPI()

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
apiKeyGoogle = os.getenv("GOOGLE_API_KEY")

assistantID = os.getenv("ASSISTANT_ID")
genai.configure(api_key=os.getenv("GENAI_API_KEY"))
model = genai.GenerativeModel('gemini-pro-vision')

KEY = os.getenv("KEY")
ALGORITHM = "HS256"



oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

credentials_exception = HTTPException(
    status_code=status.HTTP_401_UNAUTHORIZED,
    detail="Could not validate credentials",
    headers={"WWW-Authenticate": "Bearer"},
)


    
def create_access_token(data: dict):
    to_encode = data.copy()
    encoded_jwt = jwt.encode(to_encode, KEY, algorithm=ALGORITHM)
    return encoded_jwt


def hash_password(password):
    salt = bcrypt.gensalt()
    hashedPassword = bcrypt.hashpw(password.encode('utf-8'), salt)
    return hashedPassword

def verify_password(Password, hashedPassword):
    return bcrypt.checkpw(Password.encode('utf-8'), hashedPassword)



@app.get("/getLikedPosts")
async def get_liked_posts(token: str = Depends(oauth2_scheme)):
    payload = jwt.decode(token, KEY, algorithms=[ALGORITHM])
    username = payload.get("sub")
    if username is None:
        raise HTTPException(status_code=400, detail={"message": "Usuario no encontrado"})

    user = db.users.find_one({"userName": username})
    if user is None:
        raise HTTPException(status_code=400, detail={"message": "Usuario no encontrado"})

    liked_posts_ids = [ObjectId(post_id) for post_id in user.get('likes', [])]
    posts = db.posts.find({"_id": {"$in": liked_posts_ids}}).sort("timestamp", -1)
    posts_list = []
    for post in posts:
        post['_id'] = str(post['_id'])  
        post['uid'] = str(post['uid']) 
        post['isOwn'] = str(user['_id']) == post['uid']
        post['isLiked'] = str(post['_id']) in user.get('likes', [])
        posts_list.append(post)
    return {"message": "Posts obtenidos con éxito", "posts": posts_list}



@app.get("/getPosts")
async def get_posts(token: str = Depends(oauth2_scheme)):
    payload = jwt.decode(token, KEY, algorithms=[ALGORITHM])
    username = payload.get("sub")
    if username is None:
        raise HTTPException(status_code=400, detail={"message": "Usuario no encontrado"})

    user = db.users.find_one({"userName": username})
    if user is None:
        raise HTTPException(status_code=400, detail={"message": "Usuario no encontrado"})

    posts = db.posts.find().sort("timestamp", 1)
    posts_list = []
    for post in posts:
        post['_id'] = str(post['_id'])  
        post['uid'] = str(post['uid']) 
        post['isOwn'] = str(user['_id']) == post['uid']
        post['isLiked'] = str(post['_id']) in user.get('likes', [])
        posts_list.append(post)
    return {"message": "Posts obtenidos con éxito", "posts": posts_list}


@app.post("/addPost")
async def add_post(token: str = Depends(oauth2_scheme), image: UploadFile = File(...), post_info: str = Form(...)):
    payload = jwt.decode(token, KEY, algorithms=[ALGORITHM])
    username = payload.get("sub")
    if username is None:
        raise HTTPException(status_code=400, detail={"message": "Usuario no encontrado"})

    user = db.users.find_one({"userName": username})
    if user is None:
        raise HTTPException(status_code=400, detail={"message": "Usuario no encontrado"})

    post_data = {'bio': post_info}
    post_data['uid'] = str(user['_id'])
    post_data['username'] = username  # Agregar el campo username

    img = Image.open(image.file)
    img_byte_arr = io.BytesIO()
    img.save(img_byte_arr, format='JPEG')
    base64_image = base64.b64encode(img_byte_arr.getvalue()).decode('utf-8')
    post_data['image'] = base64_image

    post_data['timestamp'] = datetime.now()

    post_data['likes'] = 0

    result = db.posts.insert_one(post_data)

    post_data['_id'] = str(result.inserted_id)

    return {"message": "Post agregado con éxito", "post": post_data}


@app.delete("/deletePost/{post_id}")
async def delete_post(post_id: str, token: Optional[str] = Depends(oauth2_scheme)):
    payload = jwt.decode(token, KEY, algorithms=[ALGORITHM])
    username = payload.get("sub")
    if username is None:
        raise HTTPException(status_code=400, detail={"message": "Usuario no encontrado"})

    user = db.users.find_one({"userName": username})
    if user is None:
        raise HTTPException(status_code=400, detail={"message": "Usuario no encontrado"})

    post = db.posts.find_one({"_id": ObjectId(post_id)})
    if post is None:
        raise HTTPException(status_code=400, detail={"message": "Post no encontrado"})

    if str(post['uid']) != str(user['_id']):
        raise HTTPException(status_code=403, detail={"message": "No tienes permiso para borrar este post"})

    db.posts.delete_one({"_id": ObjectId(post_id)})

    return {"message": "Post borrado con éxito"}

@app.delete("/deletePlant")
async def delete_plant(plant_id: str, token: str = Depends(oauth2_scheme)):
    payload = jwt.decode(token, KEY, algorithms=[ALGORITHM])
    username = payload.get("sub")
    print(username)
    if username is None:
        raise HTTPException(status_code=400, detail={"message": "Usuario no encontrado"})

    user = db.users.find_one({"userName": username})
    if user is None:
        raise HTTPException(status_code=400, detail={"message": "Usuario no encontrado"})

    plant = next((plant for plant in user['plants'] if plant['id'] == plant_id), None)
    if plant is None:
        raise HTTPException(status_code=400, detail={"message": "Planta no encontrada"})

    # Eliminar la planta de la lista de plantas en la base de datos
    db.users.update_one({"userName": username}, {"$pull": {"plants": plant}})

    return {"message": "Planta eliminada con éxito"}




@app.get("/me")
async def read_users_me(token: str = Depends(oauth2_scheme)):
    print(token)
    try:
        payload = jwt.decode(token, KEY, algorithms=[ALGORITHM])
        username = payload.get("sub")
        print(username)
        if username is None:
            raise credentials_exception
        user = db.users.find_one({"userName": username})
        if user is None:
            raise credentials_exception
        return user_schema(user)
    except JWTError:
        raise HTTPException(status_code=400, detail = {"message": "Usuario no encontrado"})

@app.post("/login")
async def login(userLogin: userLogin):
    user = db.users.find_one({"$or": [{"userName": userLogin.credential}, {"email": userLogin.credential}]})
    if user:
        passwordGuardada = user["password"]
        if bcrypt.checkpw(userLogin.password.encode('utf-8'), passwordGuardada):
        
            access_token = create_access_token(
                data={"sub": user["userName"]}
            )
            return {"access_token": access_token, "token_type": "bearer"}
        else:
            raise credentials_exception
    else:
        raise HTTPException(status_code=400, detail = {"message": "Usuario no encontrado"})


@app.post("/addPlant")
async def add_plant(token: str = Depends(oauth2_scheme), image: UploadFile = File(...), plant_info: str = Form(...)):
    payload = jwt.decode(token, KEY, algorithms=[ALGORITHM])
    username = payload.get("sub")
    if username is None:
        raise HTTPException(status_code=400, detail={"message": "Usuario no encontrado"})

    user = db.users.find_one({"userName": username})
    if user is None:
        raise HTTPException(status_code=400, detail={"message": "Usuario no encontrado"})

    plant_data = json.loads(plant_info)
    plant_data['id'] = str(uuid.uuid4())

    img = Image.open(image.file)
    img_byte_arr = io.BytesIO()
    img.save(img_byte_arr, format='JPEG')
    base64_image = base64.b64encode(img_byte_arr.getvalue()).decode('utf-8')
    plant_data['image'] = base64_image

    db.users.update_one({"userName": username}, {"$push": {"plants": plant_data}})

    updated_user = db.users.find_one({"userName": username})

    return {"message": "Planta agregada con éxito", "user": user_schema(updated_user)}

@app.post("/identifyPlant")
async def identify_plant(image: UploadFile = File(...)):
    img = Image.open(image.file)
    img_byte_arr = io.BytesIO()
      
    img.save(img_byte_arr, format='JPEG')
    blob = glm.Blob(
                mime_type='image/jpeg',
                data=img_byte_arr.getvalue()
            )


    infoPlant = await post_to_gemini("Solo responde con un json de esta estrucutura con la info de la planta {name: (aqui iria el nombre de la planta), family: (aqui iria la familia de la planta), scientificName: (nombre cientifico de la planta), wateringType: (tipo de riego), indoor: (booleano en caso de q sea de interior)  }",blob)
   
    
    infoPlant = infoPlant.replace('```json\n', '').replace('```  "', '').replace('`','')
  
    json_obj = json.loads(infoPlant)
   
    return json_obj



@app.post("/register")
async def register(user: user):
    
    verficarUser = db.users.find_one({"userName": user.userName})

    if verficarUser:
        raise HTTPException(status_code=400, detail={"message": "El usuario ya está registrado"})
    

    verificarEmail = db.users.find_one({"email": user.email})
    if verificarEmail: 
          
          raise HTTPException(status_code=400, detail={"message": "El correo ya está registrado"})
    
    user_dict = dict(user)
    hashed = hash_password(user.password)
    user_dict["password"] = hashed
    verify = verify_password(user.password, hashed)
    del user_dict["id"]
    if verify:
        try:
            id = db.users.insert_one(user_dict).inserted_id
         
            access_token = create_access_token(
                data={"sub": user.userName}
            )
            
            return {"access_token": access_token, "token_type": "bearer"}
        except:
            raise HTTPException(status_code=400, detail = {"message": "error"})
        
    raise HTTPException(status_code=400, detail={"message": "error",
            "status": verify}) 
    


@app.post("/toggleLike/{post_id}")
async def toggle_like(post_id: str, token: Optional[str] = Depends(oauth2_scheme)):
    payload = jwt.decode(token, KEY, algorithms=[ALGORITHM])
    username = payload.get("sub")
    if username is None:
        raise HTTPException(status_code=400, detail={"message": "Usuario no encontrado"})

    user = db.users.find_one({"userName": username})
    if user is None:
        raise HTTPException(status_code=400, detail={"message": "Usuario no encontrado"})

    post = db.posts.find_one({"_id": ObjectId(post_id)})
    if post is None:
        raise HTTPException(status_code=400, detail={"message": "Post no encontrado"})

    if str(post['_id']) in user.get('likes', []):
        db.users.update_one({"_id": user['_id']}, {"$pull": {"likes": str(post['_id'])}})
        db.posts.update_one({"_id": post['_id']}, {"$inc": {"likes": -1}})
    else:
        db.users.update_one({"_id": user['_id']}, {"$push": {"likes": str(post['_id'])}})
        db.posts.update_one({"_id": post['_id']}, {"$inc": {"likes": 1}})

    return {"message": "Like actualizado con éxito"}   

@app.delete("/deleteUser")
async def delete_user(token: str = Depends(oauth2_scheme)):
    try:    
        payload = jwt.decode(token, KEY, algorithms=[ALGORITHM])
        username = payload.get("sub")
        
        if username is None:
            raise credentials_exception
        
        user = db.users.find_one_and_delete({"userName": username})
        if user is None:
            raise HTTPException(status_code=400, detail = {"message": "User not found"})
        
        return {"message": "Usuario eliminado con éxito"}
    except:
        raise HTTPException(status_code=400, detail = {"message": "User not found"})


async def post_to_gemini(request, image):
    response = model.generate_content([request, image], stream=True)
    response.resolve()
    description = response.text
    return description


@app.post('/assistant')
async def assistant(request: Request):
    try:
        form_data = await request.form()
        textContent = form_data['textContent']
        threadID = form_data.get('threadID')  
        image: UploadFile = form_data.get('image')
        asistente = client.beta.assistants.retrieve(
            assistant_id= assistantID
        )
        
        if threadID is None:
            thread = client.beta.threads.create()
      

        else:
            thread = client.beta.threads.retrieve(threadID)
            print(thread)
      
        

        if image is not None:
      
            img = Image.open(image.file)
            img = img.resize((150, 150))
            img_byte_arr = io.BytesIO()
      
            img.save(img_byte_arr, format='JPEG')
            blob = glm.Blob(
                mime_type='image/jpeg',
                data=img_byte_arr.getvalue()
            )


            descripcion_imagen = await post_to_gemini("Describe detalladamente la imagen",blob)
            
            message = client.beta.threads.messages.create(
                thread_id= thread.id,
                role= "user",
                content= "Responde solamente en base a esta descripcion:" + descripcion_imagen + textContent,
            )

    
        else:
            print(textContent)
            message = client.beta.threads.messages.create(
                thread_id= thread.id,
                role= "user",
                content= textContent,
            )
            print(message)

         
        run = client.beta.threads.runs.create(
            thread_id= thread.id,
            assistant_id= asistente.id,
            instructions="Responde detalladamente a cada pregunta"
        )


     
        while True:
            run_status = client.beta.threads.runs.retrieve(thread_id=thread.id, 
                                                        run_id=run.id)
            if run_status.status == "completed":
                break
            elif run_status.status == "failed":
                print("Run failed:", run_status.last_error)
                break
            time.sleep(2)  

        messages = client.beta.threads.messages.list(
            thread_id= thread.id,
        )
        assistant_messages = [msg for msg in messages.data if msg.role == 'assistant']
        if assistant_messages:
            messagesResponses = assistant_messages[0].content[0].text.value
        else:
            messagesResponses = ''

     
        return {"message": messagesResponses, "threadID": thread.id, "status_code": 200}

    except Exception as e: 
        raise HTTPException(status_code=400, detail = {"message": "No fue posible enviar el mensaje" + str(e)})




# @app.get("/users", response_model=list[user])
# async def users():
#     try:
#         return [user_schema(user) for user in db.users.find()]
#     except:
#         HTTPException(status_code=400, detail = {"message": "No users found"})

# @app.get("/user/{id}", response_model=user)
# async def user(id: str):
#     try:
#         return user_schema(db.users.find_one({"_id": id}))
#     except:
#         raise HTTPException(status_code=400, detail = {"message": "User not found"})


        


