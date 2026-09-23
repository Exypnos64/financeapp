<script lang="ts">
	import type { Account, Category, Merchant, TransactionDto, TransactionFormFailure } from '$lib';
	import { enhance } from '$app/forms';
	import { resolve } from '$app/paths';
	type Props = {
		accounts: Account[];
		categories: Category[];
		merchants: Merchant[];
		transaction?: TransactionDto;
		uuid?: ReturnType<typeof crypto.randomUUID>;
		form: TransactionFormFailure | null;
		action?: string;
		showReadOnly?: boolean;
		showDelete?: boolean;
	};

	let {
		accounts,
		categories,
		merchants,
		transaction,
		uuid,
		form,
		action = '',
		showReadOnly = false,
		showDelete = false
	}: Props = $props();
	// const moneyFormat = Intl.NumberFormat("en-US", { style: "currency", "currency": "USD" });
	// svelte-ignore state_referenced_locally
	let account = $state(Number(form?.values?.accountId ?? transaction?.accountId ?? ''));
	// svelte-ignore state_referenced_locally
	let merchant = $state(
		Number(
			form?.values?.merchantId ??
				transaction?.merchantId ??
				merchants.find((m) => m.name === 'Unknown')?.id
		)
	);
	// svelte-ignore state_referenced_locally
	let category = $state(Number(form?.values?.categoryId ?? transaction?.categoryId ?? 0));
	// svelte-ignore state_referenced_locally
	let amount = $state(form?.values?.amount ?? transaction?.amount);
	// svelte-ignore state_referenced_locally
	let cashBack = $state(form?.values?.cashBack ?? transaction?.cashBack);
	// svelte-ignore state_referenced_locally
	let setDate = $state(String(form?.values?.datePicker ?? reduceDate(transaction?.userDate ?? '')));
	// svelte-ignore state_referenced_locally
	let notes = $state(String(form?.values?.notes ?? transaction?.notes ?? ''));
	// svelte-ignore state_referenced_locally
	let storedUuid = $state(form?.values?.uuid ?? uuid);

	let categoryDropdown = $derived(categoryGroups(categories));
	let tzOffsetMins = $derived(new Date(setDate).getTimezoneOffset());

	function categoryGroups(flatList: Category[]): Map<number, Category[]> {
		const result = Map.groupBy(flatList, (c) => c.set.id);
		return result;
	}

	function reduceDate(date: string): string {
		if (date === '') return '';

		const pad = (num: number) => String(num).padStart(2, '0');
		const dateObj = new Date(date);

		const year = dateObj.getFullYear();
		const month = pad(dateObj.getMonth() + 1);
		const day = pad(dateObj.getDate());
		const hours = pad(dateObj.getHours());
		const minutes = pad(dateObj.getMinutes());

		const newDate = `${year}-${month}-${day}T${hours}:${minutes}`;
		// console.log(`Reduced date:     ${newDate}`);
		return newDate;
	}
</script>

<form method="POST" {action} use:enhance>
	{#if showReadOnly}
		<span>Original Statement:</span>
		<pre id="originalStatement" style="display: inline;">{transaction?.originalStatement}</pre>
		<br /><br />

		<span>Original Date:</span>
		<pre id="originalDate" style="display: inline;">{transaction?.originalDate}</pre>
		<br /><br />

		<span>Last Modified Date (UTC):</span>
		<pre id="lastModifiedUtc" style="display: inline;">{transaction?.lastModifiedUtc}</pre>
		<br /><br />
	{/if}

	<label for="account">Account:</label>
	<select required name="accountId" id="account" bind:value={account}>
		{#each accounts as a (a.id)}
			<option value={a.id}>{a.name}</option>
		{/each}
	</select><br /><br />

	<label for="merchant">Merchant:</label>
	<select required name="merchantId" id="merchant" bind:value={merchant}>
		{#each merchants as m (m.id)}
			<option value={m.id}>{m.name}</option>
		{/each}
	</select><br /><br />

	<label for="category">Category:</label>
	<select required name="categoryId" id="category" bind:value={category}>
		{#each categoryDropdown as [id, categoryGroup] (id)}
			<optgroup label={categoryGroup[0].set.name}>
				{#each categoryGroup as c (c.id)}
					<option value={c.id}>{c.name}</option>
				{/each}
			</optgroup>
		{/each}
	</select><br /><br />

	<label for="amount">Amount:</label>
	<input required type="number" step="0.0001" name="amount" id="amount" bind:value={amount} /><br
	/><br />

	<label for="date">Date:</label>
	<input required type="datetime-local" name="datePicker" bind:value={setDate} id="date" />
	<input type="hidden" name="userOffset" value={tzOffsetMins} /><br /><br />

	<label for="cashBack">Cash Back:</label>
	<input type="number" step="0.0001" name="cashBack" id="cashBack" bind:value={cashBack} /><br /><br
	/>

	<label for="notes">Notes:</label><br />
	<textarea name="notes" id="notes" style="height: 75px; width: 200px" bind:value={notes}
	></textarea><br /><br />

	{#if uuid}
		<input type="hidden" name="uuid" bind:value={storedUuid} />
	{/if}

	<a href={resolve('/transactions')}>Cancel</a>
	<button name="submit" type="submit">Submit</button>
	{#if showDelete}
		<button name="delete" formaction="?/delete" formnovalidate>Delete</button>
	{/if}

	{#if form?.message}
		<p>{form.message}</p>
	{/if}
</form>
