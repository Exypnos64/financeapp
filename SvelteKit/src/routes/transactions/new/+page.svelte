<script lang="ts">
    import type { PageProps } from './$types';
    import type { Category } from '$lib';
    let { data, form }: PageProps = $props();
    // const moneyFormat = Intl.NumberFormat("en-US", { style: "currency", "currency": "USD" });
    // svelte-ignore state_referenced_locally
    let account = $state(Number(form?.values?.accountId ?? ''));
    // svelte-ignore state_referenced_locally
    let merchant = $state(Number(form?.values?.merchantId ?? data.merchants.find(m => m.name === "Unknown")?.id));
    // svelte-ignore state_referenced_locally
    let category = $state(Number(form?.values?.categoryId ?? 0));
    // svelte-ignore state_referenced_locally
    let amount = $state(form?.values?.amount);
    // svelte-ignore state_referenced_locally
    let cashBack = $state(form?.values?.cashBack);
    // svelte-ignore state_referenced_locally
    let setDate = $state(String(form?.values?.datePicker ?? ''));
    // svelte-ignore state_referenced_locally
    let notes = $state(String(form?.values?.notes ?? ''));
    



    let categoryDropdown = $derived(categoryGroups(data.categories));
    let submitDate = $derived(transformDate(setDate));


    function categoryGroups(flatList: Category[]): Map<number, Category[]> {
        const result = Map.groupBy(flatList, c => c.set.id);
        return result;
    }

    function transformDate(date: string): string {
        if (date === '') return '';

        let offsetMin = new Date(date).getTimezoneOffset();
        let offsetHr = Math.trunc(offsetMin / 60);
        const sign = offsetMin > 0 ? '-' : '+';
        offsetMin -= offsetHr * 60;
        
        const hrStr = Math.abs(offsetHr).toString().padStart(2, "0");
        const minStr = Math.abs(offsetMin).toString().padStart(2, "0");
        // set seconds when date picker supports it
        return date + `:00${sign}${hrStr}:${minStr}`;
    }


</script>

<div>
    <form method="POST">
        <label for="account">Account:</label>
        <select required name="accountId" id="account" bind:value={account}>
            {#each data.accounts as a (a.id)}
            <option value={a.id}>{a.name}</option>
            {/each}
        </select><br><br>

        <label for="merchant">Merchant:</label>
        <select required name="merchantId" id="merchant" bind:value={merchant}>
            {#each data.merchants as m (m.id)}
            <option value={m.id}>{m.name}</option>
            {/each}
        </select><br><br>

        <label for="category">Category:</label>
        <select required name="categoryId" id="category" bind:value={category}>
            {#each categoryDropdown as [id, categoryGroup] (id)}
            <optgroup label={categoryGroup[0].set.name}>
                {#each categoryGroup as c (c.id)}
                <option value={c.id}>{c.name}</option>
                {/each}
            </optgroup>
            {/each} 
        </select><br><br>

        <label for="amount">Amount:</label>
        <input required type="number" step="0.0001" name="amount" id="amount" value={amount}><br><br>

        <label for="date">Date:</label>
        <input required type="datetime-local" name="datePicker" bind:value={setDate} id="date">
        <input type="hidden" name="userDate" value={submitDate}><br><br>

        <label for="cashBack">Cash Back:</label>
        <input type="number" step="0.0001" name="cashBack" id="cashBack" value={cashBack}><br><br>

        <label for="notes">Notes:</label><br>
        <textarea name="notes" id="notes" style="height: 75px; width: 200px" value={notes}></textarea><br><br>

        <button name="submit" type="submit">Submit</button>
    </form>

    {#if form?.message}
    <p>{form.message}</p>
    {/if}
</div>