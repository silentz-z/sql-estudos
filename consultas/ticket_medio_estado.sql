WITH pedido_valor AS (

    SELECT
        c.id_cliente,
        c.nome,
        c.estado,
        ps.id_pedido,

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
        ps.id_pedido

),

cliente_ticket_medio AS (

    SELECT
        pv.id_cliente,
        pv.nome,
        pv.estado,

        COUNT(DISTINCT pv.id_pedido) AS quantidade_pedidos,
        SUM(pv.valor_pedido) AS faturamento_cliente,
        AVG(pv.valor_pedido) AS ticket_medio

    FROM pedido_valor pv

    GROUP BY
        pv.id_cliente,
        pv.nome,
        pv.estado

),

cliente_ranking_ticket AS (

    SELECT
        ctm.id_cliente,
        ctm.nome,
        ctm.estado,
        ctm.quantidade_pedidos,
        ctm.faturamento_cliente,
        ctm.ticket_medio,

        RANK() OVER (
            PARTITION BY ctm.estado
            ORDER BY ctm.ticket_medio DESC
        ) AS ranking_ticket_estado

    FROM cliente_ticket_medio ctm

)

SELECT
    crt.id_cliente,
    crt.nome,
    crt.estado,
    crt.quantidade_pedidos,
    crt.faturamento_cliente,
    crt.ticket_medio,
    crt.ranking_ticket_estado

FROM cliente_ranking_ticket crt

WHERE
    crt.ranking_ticket_estado = 1

ORDER BY
    crt.estado,
    crt.ranking_ticket_estado;
