WITH cliente_faturamento_mensal AS (

    SELECT
        c.id_cliente,
        c.nome,
        DATE_TRUNC('month', ps.data_pedido) AS mes,
        SUM(ip.quantidade * p.preco) AS faturamento_mes

    FROM itens_pedido ip

    JOIN pedidos ps
        ON ps.id_pedido = ip.id_pedido

    JOIN clientes c
        ON c.id_cliente = ps.id_cliente

    JOIN produtos p
        ON p.id_produto = ip.id_produto

    GROUP BY
        c.id_cliente,
        c.nome,
        DATE_TRUNC('month', ps.data_pedido)

),

cliente_evolucao AS (

    SELECT
        cfm.id_cliente,
        cfm.nome,
        cfm.mes,
        cfm.faturamento_mes,

        LAG(cfm.faturamento_mes) OVER (
            PARTITION BY cfm.id_cliente
            ORDER BY cfm.mes
        ) AS faturamento_mes_anterior

    FROM cliente_faturamento_mensal cfm

),

cliente_ranking_mensal AS (

    SELECT
        ce.id_cliente,
        ce.nome,
        ce.mes,
        ce.faturamento_mes,
        ce.faturamento_mes_anterior,

        (ce.faturamento_mes - ce.faturamento_mes_anterior) 
            / NULLIF(ce.faturamento_mes_anterior, 0) * 100 AS variacao_percentual,

        RANK() OVER (
            PARTITION BY ce.mes
            ORDER BY ce.faturamento_mes DESC
        ) AS ranking_faturamento_mes

    FROM cliente_evolucao ce

)

SELECT
    crm.id_cliente,
    crm.nome,
    crm.mes,
    crm.faturamento_mes,
    crm.faturamento_mes_anterior,
    crm.variacao_percentual,
    crm.ranking_faturamento_mes

FROM cliente_ranking_mensal crm

WHERE
    crm.faturamento_mes > crm.faturamento_mes_anterior
    AND crm.ranking_faturamento_mes <= 5

ORDER BY
    crm.mes,
    crm.ranking_faturamento_mes;
