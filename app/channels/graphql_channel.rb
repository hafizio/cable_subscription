class GraphqlChannel < ApplicationCable::Channel
  def subscribed
    @subscription_ids = []
  end

  def execute(data)
    Rails.logger.info("QueriesChannel#execute: #{data.inspect}")

    query = data['query']
    variables = ensure_hash(data['variables'])
    operation_name = data['operationName']
    context = {
      channel: self
    }

    result = CableSubscriptionSchema.execute(
      query: query,
      context: context,
      variables: variables,
      operation_name: operation_name
    )

    payload = {
      result: result.subscription? ? { data: nil } : result.to_h,
      more: result.subscription?
    }

    if result.context[:subscription_id]
      @subscription_ids << context[:subscription_id]
    end

    transmit(payload)
  end

  def unsubscribed
    @subscription_ids.each do |sid|
      CableSubscriptionSchema.subscriptions.delete_subscription(sid)
    end
  end

  private

  def ensure_hash(query_variables)
    if query_variables.blank?
      {}
    elsif query_variables.is_a?(String)
      JSON.parse(query_variables)
    else
      query_variables
    end
  end
end