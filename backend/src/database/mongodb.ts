import mongoose from "mongoose";
import { MONGODB_URI } from "../config";

async function cleanupLegacyUserIndexes() {
    try {
        const usersCollection = mongoose.connection.collection("users");
        const indexes = await usersCollection.indexes();

        for (const index of indexes) {
            const name = index?.name || "";
            const keys = index?.key || {};
            const keyNames = Object.keys(keys).map((key) => key.toLowerCase());
            const targetsFirstName = keyNames.includes("firstname") || keyNames.includes("first_name");
            const targetsLastName = keyNames.includes("lastname") || keyNames.includes("last_name");
            const isUnique = Boolean(index?.unique);

            // Remove legacy accidental unique indexes on firstname/lastname fields.
            if (isUnique && (targetsFirstName || targetsLastName) && name !== "_id_") {
                await usersCollection.dropIndex(name);
                console.log(`Dropped legacy user index: ${name}`);
            }
        }
    } catch (error) {
        console.warn("User index cleanup skipped:", error);
    }
}

export async function connectDatabase() {
    try{
        await mongoose.connect(MONGODB_URI);
        await cleanupLegacyUserIndexes();
        console.log("Database connected successfully");
    }catch(error){
        console.log("Database Error", error);
        process.exit(1);
    }
}


export async function connectDatabaseTest(){
    try {
        await mongoose.connect(MONGODB_URI + "_test");
        await cleanupLegacyUserIndexes();
        console.log("Connected to MongoDB");
    } catch (error) {
        console.error("Database Error:", error);
        process.exit(1);
    }
}
