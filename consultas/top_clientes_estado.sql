WITH cliente_faturamento AS (

    SELECT
        c.id_cliente,
        c.nome,
        c.estado,

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
        c.estado

),

cliente_ranking AS (

    SELECT
        cf.id_cliente,
        cf.nome,
        cf.estado,
        cf.faturamento_cliente,

        RANK() OVER (
            PARTITION BY cf.estado
            ORDER BY cf.faturamento_cliente DESC
        ) AS ranking_estado

    FROM cliente_faturamento cf

)

SELECT
    cr.id_cliente,
    cr.nome,
    cr.estado,
    cr.faturamento_cliente,
    cr.ranking_estado

FROM cliente_ranking cr

WHERE
    cr.ranking_estado <= 3

ORDER BY
    cr.estado,
    cr.ranking_estado;
