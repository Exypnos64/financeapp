import type { ActionFailure } from '@sveltejs/kit';

export type Account = {
	id: number;
	typeId: number;
	name: string;
	startDateUtc: string;
	isActive: boolean;
	startBalance: number;
	lastModifiedUtc: string;
};
export type CategorySet = { id: number; name: string };
export type Category = { id: number; name: string; set: CategorySet };
export type Merchant = { id: number; name: string };
export type Transaction = {
	id: number;
	account: string;
	merchant: string;
	category: string;
	amount: number;
	cashBack: number | null;
	userDate: string;
};
export type TransactionDto = {
	id: number;
	accountId: number;
	merchantId: number;
	categoryId: number;
	amount: number;
	cashBack: number | null;
	userDate: string;
	notes: string | null;
	originalStatement: string | null;
	originalDate: string | null;
	lastModifiedUtc: string;
};

export type TransactionFormFailure = {
	message: string;
	values?: Record<string, FormDataEntryValue>;
};
export type ValidatedTransaction = {
	accountId: number;
	merchantId: number;
	categoryId: number;
	amount: number;
	cashBack: number | null;
	userDate: string;
	notes: string | null;
	idempotencyKey?: string;
};
export type TransactionValidation =
	| { ok: true; body: ValidatedTransaction }
	| { ok: false; failure: ActionFailure<TransactionFormFailure> };
