from pydantic import BaseModel

class userLogin(BaseModel):
    credential: str
    password: str

class user(userLogin):
    id: str | None
    name: str
    email: str
    userName: str
   

