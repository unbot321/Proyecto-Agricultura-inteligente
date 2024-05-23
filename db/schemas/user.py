def user_schema(user) -> dict:
    return {
        "id": str(user["_id"]),
        "userName": user["userName"],
        "name": user["name"],
        "email": user["email"],
        "password": user["password"],
        "plants": user.get("plants"),  
    }
