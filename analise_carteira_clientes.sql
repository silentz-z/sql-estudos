WITH pedido_valor AS (

    SELECT
        c.id_cliente,
        c.nome AS cliente,
        c.estado,
        ps.id_pedido,
        ps.data_pedido,
        SUM(ip.quantidade * p.preco) AS valor_pedido

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
        c.estado,
        ps.id_pedido,
        ps.data_pedido

),

cliente_metricas AS (

    SELECT
        pv.id_cliente,
        pv.cliente,
        pv.estado,

        COUNT(DISTINCT pv.id_pedido) AS qtd_pedidos,
        SUM(pv.valor_pedido) AS faturamento_total,
        SUM(pv.valor_pedido) / NULLIF(COUNT(DISTINCT pv.id_pedido), 0) AS ticket_medio,
        MAX(pv.data_pedido) AS ultima_compra,
        CURRENT_DATE - MAX(pv.data_pedido) AS dias_sem_comprar

    FROM pedido_valor pv

    GROUP BY
        pv.id_cliente,
        pv.cliente,
        pv.estado

    HAVING
        COUNT(DISTINCT pv.id_pedido) >= 3
        AND SUM(pv.valor_pedido) > 1000

),

cliente_status AS (

    SELECT
        cm.id_cliente,
        cm.cliente,
        cm.estado,
        cm.qtd_pedidos,
        cm.faturamento_total,
        cm.ticket_medio,
        cm.ultima_compra,
        cm.dias_sem_comprar,

        CASE
            WHEN cm.dias_sem_comprar <= 30 THEN 'ATIVO'
            WHEN cm.dias_sem_comprar <= 90 THEN 'RISCO'
            ELSE 'INATIVO'
        END AS status_cliente

    FROM cliente_metricas cm

),

cliente_ranking AS (

    SELECT
        cs.id_cliente,
        cs.cliente,
        cs.estado,
        cs.qtd_pedidos,
        cs.faturamento_total,
        cs.ticket_medio,
        cs.ultima_compra,
        cs.dias_sem_comprar,
        cs.status_cliente,

        RANK() OVER (
            PARTITION BY cs.estado
            ORDER BY cs.faturamento_total DESC
        ) AS ranking_estado

    FROM cliente_status cs

)

SELECT
    cr.id_cliente,
    cr.cliente,
    cr.estado,
    cr.qtd_pedidos,
    cr.faturamento_total,
    cr.ticket_medio,
    cr.ultima_compra,
    cr.dias_sem_comprar,
    cr.status_cliente,
    cr.ranking_estado

FROM cliente_ranking cr

WHERE
    cr.ranking_estado <= 5

ORDER BY
    cr.estado,
    cr.ranking_estado;
