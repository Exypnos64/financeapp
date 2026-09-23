import { fail, redirect, type ActionFailure } from '@sveltejs/kit';
import type { TransactionFormFailure, TransactionValidation } from '../types';
import { transformDate } from '../dates';

export function validateTransaction(form: FormData): TransactionValidation {
	const pickedDate = form.get('datePicker');
	if (!pickedDate || typeof pickedDate !== 'string')
		return {
			ok: false,
			failure: fail(422, {
				message: 'Please choose a date.',
				values: Object.fromEntries(form)
			})
		};

	const userDate = transformDate(pickedDate, Number(form.get('userOffset')));
	const cashBack = form.get('cashBack');
	const notes = form.get('notes');

	return {
		ok: true,
		body: {
			accountId: Number(form.get('accountId')),
			merchantId: Number(form.get('merchantId')),
			categoryId: Number(form.get('categoryId')),
			amount: Number(form.get('amount')),
			cashBack: cashBack && typeof cashBack === 'string' ? Number(cashBack) : null,
			userDate: userDate,
			notes: notes && typeof notes === 'string' ? notes : null
		}
	};
}

export async function handleTransactionResponse(
	response: Response,
	form?: FormData
): Promise<ActionFailure<TransactionFormFailure> | undefined> {
	if (response.ok) {
		redirect(303, '/transactions');
	} else {
		return fail(response.status, {
			message: await response.text(),
			...(form !== undefined && { values: Object.fromEntries(form) })
		});
	}
}
