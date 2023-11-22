CREATE MODEL falcon_7b_instruct_llm_model
FUNCTION falcon_7b_instruct_llm_model(super)
RETURNS super
SAGEMAKER '<endpointname>'
IAM_ROLE default;

CREATE TABLE amazon_reviews
(
    title varchar(200),
    review varchar(4000)
);

COPY amazon_reviews 
FROM 's3://redshift-blogs/redshift-llm-blog/amazon_reviews_csv.csv'
IAM_ROLE DEFAULT
csv
DELIMITER ','
IGNOREHEADER 1
ACCEPTINVCHARS '?';

CREATE FUNCTION udf_prompt_eng_sentiment_analysis (varchar)
  returns super
stable
as $$
  select json_parse(
  '{"inputs":"Classify the sentiment of this sentence as Positive, Negative, Neutral. Return only the sentiment nothing else.' || $1 || '","parameters":{"max_new_tokens":1000}}')
$$ language sql;

CREATE table sentiment_analysis_for_amazon_reviews
as
(
    SELECT 
        title, 
        review, 
        falcon_7b_instruct_llm_model
            (
                udf_prompt_eng_sentiment_analysis(review)
        ) as sentiment
    from amazon_reviews
);

SELECT review, sentiment[0]."generated_text" :: varchar as sentiment
FROM sentiment_analysis_for_amazon_reviews;