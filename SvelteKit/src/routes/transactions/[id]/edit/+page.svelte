<script lang="ts">
    import TransactionForm from '$lib/components/TransactionForm.svelte';
    import type { PageProps } from './$types';
    let { data, form }: PageProps = $props();
</script>

{#key data.transaction.id}
<TransactionForm
    accounts={data.accounts}
    categories={data.categories}
    merchants={data.merchants}
    transaction={data.transaction}
    {form}
    action="?/update"
    showDelete
    showReadOnly
/>
{/key}
