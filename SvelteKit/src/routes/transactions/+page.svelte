<script lang="ts">
    import type { PageProps } from "./$types";
    let { data }: PageProps = $props();
    const moneyFormat = Intl.NumberFormat("en-US", { style: "currency", "currency": "USD" });
</script>

<div>
    <table>
        <thead>
            <tr>
                <th scope="col">Account</th>
                <th scope="col">Merchant</th>
                <th scope="col">Category</th>
                <th scope="col">Amount</th>
                <th scope="col">Cash Back</th>
                <th scope="col">User Date</th>
            </tr>
        </thead>
        <tbody>
            {#each data.transactions as transaction (transaction.id)}
            <tr>
                <td>{transaction.account}</td>
                <td>{transaction.merchant}</td>
                <td>{transaction.category}</td>
                <td>{moneyFormat.format(transaction.amount)}</td>
                <td>{transaction.cashBack ? moneyFormat.format(transaction.cashBack) : ""}</td>
                <td>{new Date(transaction.userDate).toLocaleDateString("en-US", { day: "2-digit", "month": "2-digit", "year": "2-digit" })}</td>
            </tr>
            {/each}
        </tbody>
    </table>
</div>