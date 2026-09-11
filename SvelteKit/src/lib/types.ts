export type Account = { id: number, typeId: number, name: string, startDateUtc: string, isActive: boolean, startBalance: number, lastModifiedUtc: string };
export type CategorySet = { id: number, name: string };
export type Category = { id: number, name: string, set: CategorySet };
export type Merchant = { id: number, name: string };
export type Transaction = { id: number, account: string, merchant: string, category: string, amount: number, cashBack: number | null, userDate: string };
