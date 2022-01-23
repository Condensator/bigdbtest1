SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CreditProfileAdditionalCharges](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AdditionalChargeId] [bigint] NOT NULL,
	[CreditProfileId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CreditProfileAdditionalCharges]  WITH CHECK ADD  CONSTRAINT [ECreditProfile_CreditProfileAdditionalCharges] FOREIGN KEY([CreditProfileId])
REFERENCES [dbo].[CreditProfiles] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CreditProfileAdditionalCharges] CHECK CONSTRAINT [ECreditProfile_CreditProfileAdditionalCharges]
GO
ALTER TABLE [dbo].[CreditProfileAdditionalCharges]  WITH CHECK ADD  CONSTRAINT [ECreditProfileAdditionalCharge_AdditionalCharge] FOREIGN KEY([AdditionalChargeId])
REFERENCES [dbo].[AdditionalCharges] ([Id])
GO
ALTER TABLE [dbo].[CreditProfileAdditionalCharges] CHECK CONSTRAINT [ECreditProfileAdditionalCharge_AdditionalCharge]
GO
