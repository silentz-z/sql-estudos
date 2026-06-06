WITH cliente_faturamento_mensal AS (

    SELECT
        c.id_cliente,
        c.nome,
        DATE_TRUNC('month', ps.data_pedido) AS mes,

        SUM(ip.quantidade * p.preco) AS faturamento_cliente

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

cliente_faturamento_total AS (

    SELECT
        cfm.id_cliente,
        cfm.nome,
        cfm.mes,
        cfm.faturamento_cliente,

        SUM(cfm.faturamento_cliente) OVER (
            PARTITION BY cfm.mes
        ) AS faturamento_total_mes

    FROM cliente_faturamento_mensal cfm

),

cliente_curva_abc AS (

    SELECT
        cft.id_cliente,
        cft.nome,
        cft.mes,
        cft.faturamento_cliente,
        cft.faturamento_total_mes,

        (cft.faturamento_cliente / NULLIF(cft.faturamento_total_mes, 0)) * 100 AS percentual_participacao,

        SUM(cft.faturamento_cliente) OVER (
            PARTITION BY cft.mes
            ORDER BY cft.faturamento_cliente DESC
        ) AS faturamento_acumulado

    FROM cliente_faturamento_total cft

)

SELECT
    cca.id_cliente,
    cca.nome,
    cca.mes,
    cca.faturamento_cliente,
    cca.faturamento_total_mes,

    cca.percentual_participacao,

    (cca.faturamento_acumulado / NULLIF(cca.faturamento_total_mes, 0)) * 100 AS percentual_acumulado,

    CASE
        WHEN (cca.faturamento_acumulado / NULLIF(cca.faturamento_total_mes, 0)) * 100 <= 80 THEN 'A'
        WHEN (cca.faturamento_acumulado / NULLIF(cca.faturamento_total_mes, 0)) * 100 <= 95 THEN 'B'
        ELSE 'C'
    END AS curva_abc

FROM cliente_curva_abc cca

ORDER BY
    cca.mes,
    cca.faturamento_cliente DESC;
