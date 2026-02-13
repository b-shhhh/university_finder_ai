// src/repositories/country.repository.ts
import { Country, ICountry } from "../models/country.model";

export class CountryRepository {
    async createCountry(data: Partial<ICountry>): Promise<ICountry> {
        const country = new Country(data);
        return country.save();
    }

    async findAll(): Promise<ICountry[]> {
        return Country.find();
    }

    async findByName(name: string): Promise<ICountry | null> {
        return Country.findOne({ name });
    }
}
