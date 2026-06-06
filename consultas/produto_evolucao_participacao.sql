WITH produto_faturamento_mensal AS (

    SELECT
        p.id_produto,
        p.nome AS produto,
        DATE_TRUNC('month', ps.data_pedido) AS mes,
        SUM(ip.quantidade * p.preco) AS faturamento_produto

    FROM itens_pedido ip

    JOIN pedidos ps
        ON ps.id_pedido = ip.id_pedido

    JOIN produtos p
        ON p.id_produto = ip.id_produto

    GROUP BY
        p.id_produto,
        p.nome,
        DATE_TRUNC('month', ps.data_pedido)

),

produto_metricas_mensais AS (

    SELECT
        pfm.id_produto,
        pfm.produto,
        pfm.mes,
        pfm.faturamento_produto,

        LAG(pfm.faturamento_produto) OVER (
            PARTITION BY pfm.id_produto
            ORDER BY pfm.mes
        ) AS faturamento_produto_anterior,

        SUM(pfm.faturamento_produto) OVER (
            PARTITION BY pfm.mes
        ) AS faturamento_total_mes

    FROM produto_faturamento_mensal pfm

),

produto_participacao_mensal AS (

    SELECT
        pmm.id_produto,
        pmm.produto,
        pmm.mes,
        pmm.faturamento_produto,
        pmm.faturamento_produto_anterior,
        pmm.faturamento_total_mes,

        LAG(pmm.faturamento_total_mes) OVER (
            PARTITION BY pmm.id_produto
            ORDER BY pmm.mes
        ) AS faturamento_total_mes_anterior,

        (pmm.faturamento_produto / NULLIF(pmm.faturamento_total_mes, 0)) * 100 AS percentual_participacao,

        RANK() OVER (
            PARTITION BY pmm.mes
            ORDER BY pmm.faturamento_produto DESC
        ) AS ranking_faturamento_mes

    FROM produto_metricas_mensais pmm

),

produto_evolucao_participacao AS (

    SELECT
        ppm.id_produto,
        ppm.produto,
        ppm.mes,
        ppm.faturamento_produto,
        ppm.faturamento_produto_anterior,
        ppm.faturamento_total_mes,
        ppm.faturamento_total_mes_anterior,
        ppm.percentual_participacao,

        LAG(ppm.percentual_participacao) OVER (
            PARTITION BY ppm.id_produto
            ORDER BY ppm.mes
        ) AS percentual_participacao_anterior,

        ppm.ranking_faturamento_mes

    FROM produto_participacao_mensal ppm

)

SELECT
    pep.id_produto,
    pep.produto,
    pep.mes,
    pep.faturamento_produto,
    pep.faturamento_produto_anterior,
    pep.faturamento_total_mes,
    COALESCE(pep.faturamento_total_mes_anterior, 0) AS faturamento_total_mes_anterior,
    pep.percentual_participacao,
    pep.percentual_participacao_anterior,
    pep.percentual_participacao - pep.percentual_participacao_anterior AS variacao_participacao,
    pep.ranking_faturamento_mes

FROM produto_evolucao_participacao pep

WHERE
    pep.ranking_faturamento_mes BETWEEN 1 AND 5
    AND pep.percentual_participacao_anterior < pep.percentual_participacao

ORDER BY
    pep.mes,
    pep.ranking_faturamento_mes;
