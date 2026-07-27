<script lang="ts">
    import type { PageProps } from './$types';
    let { data }: PageProps = $props();
</script>


<div>
    <table>
        <thead>
            <tr>
                <th scope="col">Id</th>
                <th scope="col">TypeId</th>
                <th scope="col">Name</th>
                <th scope="col">StartDateUtc</th>
                <th scope="col">IsActive</th>
                <th scope="col">StartBalance</th>
                <th scope="col">LastModifiedUtc</th>
            </tr>
        </thead>
        <tbody>
            {#each data.accounts as account (account.id)}
            <tr>
                <th scope="row">{account.id}</th>
                <td>{account.typeId}</td>
                <td>{account.name}</td>
                <td>{account.startDateUtc}</td>
                <td>{account.isActive}</td>
                <td>{account.startBalance}</td>
                <td>{account.lastModifiedUtc}</td>
            </tr>
            {/each}
        </tbody>

    </table>
</div>